import ConductorCore
import SwiftUI

@MainActor
struct RunView: View {
    let store: ConductorStore
    @State private var stoppingSession: RunSession?

    var body: some View {
        Group {
            if let session = store.workspace.session {
                TimelineView(.periodic(from: Date(), by: 1)) { context in
                    List {
                        if store.isReadOnly { RecoverySection(store: store) }
                        if store.notice != nil { Section { NoticeView(store: store) } }
                        Section {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(session.plan.title).font(.title2.bold())
                                Text("Shared finish · \(TimeText.fullDate(session.commonFinish))")
                                    .font(.headline).foregroundStyle(.indigo)
                                Text(status(session))
                                    .font(.subheadline).foregroundStyle(.secondary)
                            }.padding(.vertical, 8)
                        }
                        Section("Your tasks") {
                            ForEach(session.tasks) { task in
                                RunTaskRow(task: task, session: session, now: context.date, store: store)
                            }
                        }
                        Section {
                            Text("Time reaching zero is a cue, not confirmation that a physical task is finished. Mark Done when it actually is.")
                                .font(.footnote).foregroundStyle(.secondary)
                        }
                    }
                }
                .toolbar {
                    if ScheduleEngine.isActive(session) {
                        Button("Stop Run", role: .destructive) { stoppingSession = session }.disabled(store.isReadOnly)
                    }
                }
            } else {
                ContentUnavailableView {
                    Label("One finish, a clear start", systemImage: "timer")
                } description: {
                    Text("Choose a plan and set its shared finish time. The start cues will appear here.")
                } actions: {
                    Button("See Plans") { store.selectedTab = .plans }.buttonStyle(.borderedProminent)
                }
            }
        }
        .navigationTitle("Current Run")
        .confirmationDialog("Stop this run?", isPresented: Binding(
            get: { stoppingSession != nil }, set: { if !$0 { stoppingSession = nil } }), titleVisibility: .visible) {
                if let session = stoppingSession {
                    Button("Stop Run", role: .destructive) { store.stopRun(id: session.id); stoppingSession = nil }
                }
                Button("Keep Running", role: .cancel) { stoppingSession = nil }
            } message: { Text("Progress remains visible, but remaining start and time-elapsed reminders are canceled after the stop is saved.") }
    }

    private func status(_ session: RunSession) -> String {
        if session.stoppedAt != nil { return "Stopped · progress retained" }
        if !ScheduleEngine.isActive(session) { return "All tasks checked off or skipped" }
        let complete = session.tasks.filter { $0.phase == .completed }.count
        let included = session.tasks.filter { $0.phase != .skipped }.count
        return "\(complete) of \(included) included tasks confirmed done"
    }
}
