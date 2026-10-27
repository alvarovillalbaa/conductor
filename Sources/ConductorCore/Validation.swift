import Foundation

extension ScheduleEngine {
    public static func validate(_ workspace: Workspace) throws {
        guard workspace.version == 1 else {
            throw ConductorError.invalidData("This workspace version is not supported. Keep the original file for recovery.")
        }
        guard workspace.plans.count <= maximumPlans,
              Set(workspace.plans.map(\.id)).count == workspace.plans.count else {
            throw ConductorError.invalidData("The workspace has too many plans or duplicate plan identities.")
        }
        for plan in workspace.plans { try validate(plan) }
        if let session = workspace.session { try validateSession(session) }
    }

    public static func validate(_ plan: TaskPlan) throws {
        guard validTitle(plan.title), plan.revision >= 0 else {
            throw ConductorError.invalidPlan("Use a plan title of 1–80 characters and a valid revision.")
        }
        try validateDate(plan.updatedAt)
        guard (1...maximumTasks).contains(plan.tasks.count),
              Set(plan.tasks.map(\.id)).count == plan.tasks.count else {
            throw ConductorError.invalidPlan("Keep 1–20 tasks with distinct identities in each plan.")
        }
        for task in plan.tasks {
            guard validTitle(task.title), (1...maximumDurationSeconds).contains(task.durationSeconds) else {
                throw ConductorError.invalidPlan("Each task needs a title of 1–80 characters and a duration from one second to 24 hours.")
            }
        }
    }

    static func validateSession(_ session: RunSession) throws {
        try validate(session.plan)
        try validateDate(session.createdAt)
        try validateDate(session.commonFinish)
        if let stoppedAt = session.stoppedAt { try validateDate(stoppedAt) }
        let earliest = try earliestFinish(for: session.plan, now: session.createdAt)
        guard session.commonFinish >= earliest,
              session.commonFinish <= session.createdAt.addingTimeInterval(maximumHorizonSeconds) else {
            throw ConductorError.invalidRun("The run has an impossible shared finish time.")
        }
        guard session.tasks.count == session.plan.tasks.count,
              Set(session.tasks.map(\.id)).count == session.tasks.count else {
            throw ConductorError.invalidRun("The run must contain each planned task exactly once.")
        }
        let definitions = Dictionary(uniqueKeysWithValues: session.plan.tasks.map { ($0.id, $0) })
        for task in session.tasks {
            guard definitions[task.id] == task.definition else {
                throw ConductorError.invalidRun("A task no longer matches its frozen run definition.")
            }
            try validateRunTask(task)
        }
        if session.stoppedAt != nil {
            guard !session.tasks.contains(where: { $0.phase == .running }),
                  session.tasks.contains(where: { !isTerminal($0.phase) }) else {
                throw ConductorError.invalidRun("A stopped run has inconsistent task states.")
            }
        }
    }

    static func validateRunTask(_ task: RunTask) throws {
        guard task.elapsedBeforeRun.isFinite, task.elapsedBeforeRun >= 0 else {
            throw ConductorError.invalidRun("Saved elapsed time must be finite and nonnegative.")
        }
        for date in [task.runningSince, task.firstStartedAt, task.endedAt].compactMap({ $0 }) {
            try validateDate(date)
        }
        let valid: Bool
        switch task.phase {
        case .waiting:
            valid = task.elapsedBeforeRun == 0 && task.runningSince == nil
                && task.firstStartedAt == nil && task.endedAt == nil
        case .running:
            valid = task.runningSince != nil && task.firstStartedAt != nil && task.endedAt == nil
        case .paused:
            valid = task.runningSince == nil && task.firstStartedAt != nil && task.endedAt == nil
        case .completed, .skipped:
            valid = task.runningSince == nil && task.endedAt != nil
                && (task.firstStartedAt != nil || task.elapsedBeforeRun == 0)
        }
        guard valid else { throw ConductorError.invalidRun("A saved task has inconsistent timing state.") }
    }

    static func validTitle(_ value: String) -> Bool {
        value.utf8.count <= 4_096 && value.count <= 80
            && !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    static func validateDate(_ date: Date) throws {
        let seconds = date.timeIntervalSince1970
        guard seconds.isFinite, seconds >= 0, seconds <= 32_503_680_000 else {
            throw ConductorError.invalidData("Dates must be finite and between 1970 and the start of year 3000.")
        }
    }

    static func isTerminal(_ phase: TaskPhase) -> Bool { phase == .completed || phase == .skipped }
}
