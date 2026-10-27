import ConductorCore
import SwiftUI

@MainActor
struct PlanEditorView: View {
    @Environment(\.dismiss) private var dismiss
    let context: PlanEditorContext
    let store: ConductorStore
    private let planID: UUID
    @State private var title: String
    @State private var tasks: [DraftTask]
    @State private var errorMessage: String?
    @State private var failedCandidate: Data?

    init(context: PlanEditorContext, store: ConductorStore) {
        self.context = context
        self.store = store
        planID = context.original?.id ?? context.id
        _title = State(initialValue: context.original?.title ?? "")
        _tasks = State(initialValue: context.original?.tasks.map { DraftTask($0) } ?? [DraftTask()])
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Plan") {
                    TextField("Name, such as Dinner together", text: $title)
                    Text("Name the plan and each task in 80 characters or fewer.").font(.caption).foregroundStyle(.secondary)
                }
                Section {
                    ForEach($tasks) { $task in DraftTaskEditor(task: $task) }
                        .onDelete { tasks.remove(atOffsets: $0) }
                        .onMove { tasks.move(fromOffsets: $0, toOffset: $1) }
                    Button { tasks.append(DraftTask()) } label: { Label("Add Task", systemImage: "plus") }
                        .disabled(tasks.count >= ScheduleEngine.maximumTasks)
                } header: {
                    Text("Tasks · \(tasks.count)/\(ScheduleEngine.maximumTasks)")
                } footer: {
                    Text("Durations can be 1 second to 24 hours. Reordering changes the plan's display order, not the shared finish calculation.")
                }
                if let errorMessage {
                    Section("Not saved") {
                        Text(errorMessage).foregroundStyle(.red).textSelection(.enabled)
                        if let failedCandidate {
                            DataExportButton(title: "Export Last Save Attempt") {
                                try DataExport.prepare(data: failedCandidate, name: "Conductor-unsaved.json")
                            }
                            Text("This copy contains the failed save's values, which may differ from your current edits.")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        if context.original != nil {
                            Button("Save Draft as a New Plan") { save(asNew: true) }
                                .disabled(store.isReadOnly)
                        }
                    }
                }
                Section {
                    Text("Editing this plan applies to future runs. A current run keeps its own definitions.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle(context.original == nil ? "New Plan" : "Edit Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") { save(asNew: false) }.fontWeight(.semibold).disabled(store.isReadOnly)
                }
                ToolbarItem(placement: .bottomBar) { EditButton() }
            }
        }
        .interactiveDismissDisabled(errorMessage != nil)
    }

    private func save(asNew: Bool) {
        do {
            try store.savePlan(id: asNew ? UUID() : planID,
                               title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                               tasks: tasks.map(\.definition), expectedRevision: asNew ? nil : context.original?.revision)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            failedCandidate = (error as? CandidateSaveError)?.candidateData
        }
    }
}

@MainActor
private struct DraftTaskEditor: View {
    @Binding var task: DraftTask

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField("Task name", text: $task.title)
            Stepper("Hours: \(task.hours)", value: $task.hours, in: 0...24)
                .accessibilityLabel("\(task.title.isEmpty ? "Task" : task.title) hours")
            Stepper("Minutes: \(task.minutes)", value: $task.minutes, in: 0...59)
                .accessibilityLabel("\(task.title.isEmpty ? "Task" : task.title) minutes")
            Stepper("Seconds: \(task.seconds)", value: $task.seconds, in: 0...59)
                .accessibilityLabel("\(task.title.isEmpty ? "Task" : task.title) seconds")
        }.padding(.vertical, 6)
    }
}
