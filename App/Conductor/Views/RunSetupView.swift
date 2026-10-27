import ConductorCore
import SwiftUI

@MainActor
struct RunSetupView: View {
    @Environment(\.dismiss) private var dismiss
    let context: RunSetupContext
    let store: ConductorStore
    @State private var finishAt: Date
    @State private var useSoonest = false
    @State private var confirmingReplacement = false
    @State private var errorMessage: String?
    @State private var failedCandidate: Data?

    init(context: RunSetupContext, store: ConductorStore) {
        self.context = context
        self.store = store
        let duration = context.plan.tasks.map(\.durationSeconds).max() ?? 0
        let initial = Date().addingTimeInterval(TimeInterval(duration) + 300).timeIntervalSince1970
        _finishAt = State(initialValue: Date(timeIntervalSince1970: ceil(initial / 60) * 60))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(context.plan.title) {
                    Toggle("Use the soonest possible finish", isOn: $useSoonest)
                    if useSoonest {
                        Text("The target is recalculated when you create the run. The longest task will be due immediately; press Start when you actually begin it.")
                            .font(.callout).foregroundStyle(.secondary)
                    } else {
                        DatePicker("Finish together at", selection: $finishAt, displayedComponents: [.date, .hourAndMinute])
                    }
                    Text("A run freezes this plan. Its timers start only when you explicitly start each task.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                if !useSoonest {
                    Section("Planned starts") {
                        ForEach(context.plan.tasks) { task in
                            VStack(alignment: .leading, spacing: 5) {
                                Text(task.title)
                                Text(TimeText.fullDate(finishAt.addingTimeInterval(-TimeInterval(task.durationSeconds))))
                                    .font(.subheadline).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                if let existing = context.existingSession {
                    Section("Existing run") {
                        Text("Creating this run replaces “\(existing.plan.title)”. Saved plans remain unchanged.")
                        DataExportButton(title: "Export Current Data First") { try store.exportCurrent() }
                    }
                }
                if let errorMessage {
                    Section("Run not created") {
                        Text(errorMessage).foregroundStyle(.red).textSelection(.enabled)
                        if let failedCandidate {
                            DataExportButton(title: "Export Last Save Attempt") {
                                try DataExport.prepare(data: failedCandidate, name: "Conductor-unsaved.json")
                            }
                            Text("This copy contains the failed save's values, which may differ from your current edits.")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Shared Finish")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .primaryAction) {
                    Button("Create Run") {
                        if context.existingSession == nil { create() } else { confirmingReplacement = true }
                    }.fontWeight(.semibold).disabled(store.isReadOnly)
                }
            }
            .confirmationDialog("Replace the existing run?", isPresented: $confirmingReplacement, titleVisibility: .visible) {
                Button("Replace Run", role: .destructive) { create() }
                Button("Keep Existing Run", role: .cancel) {}
            } message: {
                Text("The previous run's progress will be replaced. Its plan stays available; export current data first if you want a copy.")
            }
        }
        .interactiveDismissDisabled(errorMessage != nil)
    }

    private func create() {
        do {
            try store.startRun(plan: context.plan, finishAt: useSoonest ? nil : finishAt,
                               replaceRunID: context.existingSession?.id)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            failedCandidate = (error as? CandidateSaveError)?.candidateData
        }
    }
}
