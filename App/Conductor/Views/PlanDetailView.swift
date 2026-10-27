import SwiftUI

@MainActor
struct PlanDetailView: View {
    let id: UUID
    let store: ConductorStore

    var body: some View {
        Group {
            if let plan = store.plan(id) {
                List {
                    if store.notice != nil { Section { NoticeView(store: store) } }
                    Section {
                        Button { store.setUpRun(plan) } label: {
                            Label("Choose a Finish Time", systemImage: "flag.checkered")
                        }.disabled(store.isReadOnly)
                    }
                    Section("Tasks") {
                        ForEach(plan.tasks) { task in
                            HStack {
                                Text(task.title)
                                Spacer()
                                Text(TimeText.duration(TimeInterval(task.durationSeconds))).monospacedDigit().foregroundStyle(.secondary)
                            }
                        }
                    }
                    Section {
                        Text("All tasks share a target finish. You choose when you actually start, pause and complete each one.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }
                .navigationTitle(plan.title)
                .toolbar { Button("Edit") { store.editPlan(plan) }.disabled(store.isReadOnly) }
            } else {
                ContentUnavailableView("Plan unavailable", systemImage: "doc.questionmark",
                                       description: Text("It may have been removed in another window. Return to your plans."))
            }
        }
    }
}
