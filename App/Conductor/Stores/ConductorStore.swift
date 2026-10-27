import ConductorCore
import Foundation
import Observation

@MainActor
@Observable
final class ConductorStore {
    private(set) var workspace = Workspace()
    private(set) var recoveryMessage: String?
    private(set) var reminderUpdate: ReminderUpdate?
    private(set) var isRequestingPermission = false
    private(set) var unsavedData: Data?
    var notice: AppNotice?
    var selectedTab: AppTab = .plans
    var sheet: AppSheet?

    @ObservationIgnored private let files = WorkspaceFileStore()
    @ObservationIgnored private let reminders = ReminderService()
    @ObservationIgnored private var reminderTask: Task<Void, Never>?
    @ObservationIgnored private var authorizationTask: Task<Void, Never>?
    @ObservationIgnored private var reminderGeneration = UUID()
    @ObservationIgnored private var authorizationGeneration = UUID()

    init() {
        do {
            workspace = try files.load()
            if workspace.session != nil { selectedTab = .run }
        }
        catch { recoveryMessage = error.localizedDescription }
    }

    deinit {
        reminderTask?.cancel()
        authorizationTask?.cancel()
    }

    var isReadOnly: Bool { recoveryMessage != nil }

    func plan(_ id: UUID) -> TaskPlan? { workspace.plans.first { $0.id == id } }
    func createPlan() { guard !isReadOnly else { return }; sheet = .plan(PlanEditorContext(original: nil)) }
    func editPlan(_ plan: TaskPlan) { guard !isReadOnly else { return }; sheet = .plan(PlanEditorContext(original: plan)) }
    func setUpRun(_ plan: TaskPlan) {
        guard !isReadOnly else { return }
        sheet = .run(RunSetupContext(plan: plan, existingSession: workspace.session))
    }

    func savePlan(id: UUID, title: String, tasks: [TaskDefinition], expectedRevision: Int?) throws {
        guard !isReadOnly else { throw LocalDataError.recoveryRequired }
        var candidate = workspace
        if let expectedRevision {
            guard let index = candidate.plans.firstIndex(where: { $0.id == id }),
                  candidate.plans[index].revision == expectedRevision else { throw LocalDataError.changedPlan }
            let (revision, overflow) = expectedRevision.addingReportingOverflow(1)
            guard !overflow else { throw LocalDataError.revisionLimit }
            candidate.plans[index] = TaskPlan(id: id, title: title, tasks: tasks, revision: revision, updatedAt: Date())
        } else {
            guard !candidate.plans.contains(where: { $0.id == id }) else { throw LocalDataError.changedPlan }
            candidate.plans.append(TaskPlan(id: id, title: title, tasks: tasks, revision: 0, updatedAt: Date()))
        }
        try commit(candidate)
    }

    func deletePlan(id: UUID, expectedRevision: Int) {
        attempt {
            guard let existing = workspace.plans.first(where: { $0.id == id }),
                  existing.revision == expectedRevision else { throw LocalDataError.changedPlan }
            var candidate = workspace
            candidate.plans.removeAll { $0.id == id }
            try commit(candidate)
        }
    }

    func startRun(plan: TaskPlan, finishAt: Date?, replaceRunID: UUID?) throws {
        guard !isReadOnly else { throw LocalDataError.recoveryRequired }
        guard let current = self.plan(plan.id), current.revision == plan.revision else { throw LocalDataError.changedPlan }
        guard workspace.session?.id == replaceRunID else { throw LocalDataError.changedRun }
        let now = Date()
        let target = try finishAt ?? ScheduleEngine.earliestFinish(for: current, now: now)
        let session = try ScheduleEngine.start(plan: current, finishAt: target, now: now)
        var candidate = workspace
        candidate.session = session
        try commit(candidate)
        selectedTab = .run
    }

    func act(_ action: RunAction, sessionID: UUID, taskID: UUID) {
        attempt {
            guard let session = workspace.session, session.id == sessionID else { throw LocalDataError.changedRun }
            var candidate = workspace
            candidate.session = try ScheduleEngine.applying(action, to: session, taskID: taskID, now: Date())
            try commit(candidate)
        }
    }

    func stopRun(id: UUID) {
        attempt {
            guard let session = workspace.session, session.id == id else { throw LocalDataError.changedRun }
            var candidate = workspace
            candidate.session = try ScheduleEngine.stop(session, now: Date())
            try commit(candidate)
        }
    }

    private func commit(_ candidate: Workspace) throws {
        guard !isReadOnly else { throw LocalDataError.recoveryRequired }
        let data = try WorkspaceCodec.encode(candidate)
        do { try files.save(data) }
        catch {
            unsavedData = data
            throw CandidateSaveError(message: "Could not save these changes: \(error.localizedDescription)", candidateData: data)
        }
        workspace = candidate
        unsavedData = nil
        notice = nil
        reconcileReminders()
    }

    private func attempt(_ action: () throws -> Void) {
        do { try action() }
        catch { notice = AppNotice(message: error.localizedDescription, isError: true) }
    }

    func reloadSavedData() {
        authorizationGeneration = UUID()
        authorizationTask?.cancel()
        isRequestingPermission = false
        do {
            let loaded = try files.load()
            workspace = loaded
            recoveryMessage = nil
            notice = AppNotice(message: unsavedData == nil ? "The complete saved workspace was opened."
                : "The saved workspace was opened. Previous unsaved changes remain available to export.", isError: false)
        } catch {
            recoveryMessage = error.localizedDescription
            notice = AppNotice(message: "Saved data is unchanged. \(error.localizedDescription)", isError: true)
        }
        reconcileReminders()
    }

    func enableReminders() {
        guard !isReadOnly, !isRequestingPermission else { return }
        let token = UUID()
        authorizationGeneration = token
        isRequestingPermission = true
        authorizationTask = Task { [weak self] in
            guard let self, !Task.isCancelled, self.authorizationGeneration == token, !self.isReadOnly else { return }
            do {
                let allowed = try await reminders.requestAccess()
                guard !Task.isCancelled, authorizationGeneration == token, !isReadOnly else { return }
                isRequestingPermission = false
                guard allowed else {
                    notice = AppNotice(message: "iOS did not allow reminders. You can change this in Settings; live cues still work here.", isError: true)
                    reconcileReminders()
                    return
                }
                var candidate = workspace
                candidate.remindersEnabled = true
                try commit(candidate)
            } catch {
                guard !Task.isCancelled, authorizationGeneration == token else { return }
                isRequestingPermission = false
                notice = AppNotice(message: error.localizedDescription, isError: true)
            }
        }
    }

    func disableReminders() {
        authorizationGeneration = UUID()
        authorizationTask?.cancel()
        isRequestingPermission = false
        attempt {
            var candidate = workspace
            candidate.remindersEnabled = false
            try commit(candidate)
        }
    }

    func reconcileReminders() {
        reminderTask?.cancel()
        let token = UUID()
        reminderGeneration = token
        let enabled = !isReadOnly && workspace.remindersEnabled
        let cues = workspace.session.map { ScheduleEngine.reminders(for: $0, now: Date()) } ?? []
        reminderTask = Task { [weak self, reminders] in
            let update = await reminders.reconcile(cues: cues, enabled: enabled)
            guard !Task.isCancelled, let self, self.reminderGeneration == token, let update else { return }
            self.reminderUpdate = update
        }
    }

    func exportCurrent() throws -> ExportCopy { try DataExport.prepare(data: WorkspaceCodec.encode(workspace)) }
    func exportOriginal() throws -> ExportCopy {
        guard let url = files.fileURL else { throw LocalDataError.unavailableDirectory }
        return try DataExport.prepare(original: url)
    }
    func exportUnsaved() throws -> ExportCopy {
        guard let unsavedData else { throw CocoaError(.fileReadNoSuchFile) }
        return try DataExport.prepare(data: unsavedData, name: "Conductor-unsaved.json")
    }
}
