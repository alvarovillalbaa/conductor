import ConductorCore
import SwiftUI

@MainActor
struct RunTaskRow: View {
    let task: RunTask
    let session: RunSession
    let now: Date
    let store: ConductorStore

    private var timing: TaskTiming { ScheduleEngine.timing(for: task, in: session, now: now) }
    private var active: Bool { ScheduleEngine.isActive(session) && !store.isReadOnly }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(task.definition.title).font(.headline)
                Spacer()
                Text(TimeText.phase(task.phase)).font(.caption.weight(.semibold))
                    .foregroundStyle(timing.isDue || timing.isOvertime ? Color.orange : Color.secondary)
            }
            Text("Planned start \(TimeText.fullDate(timing.plannedStart)) · \(TimeText.duration(TimeInterval(task.definition.durationSeconds)))")
                .font(.caption).foregroundStyle(.secondary)
            timingDescription
            if active && task.phase != .completed && task.phase != .skipped {
                ViewThatFits(in: .horizontal) {
                    HStack { controls }
                    VStack(alignment: .leading) { controls }
                }
                .buttonStyle(.bordered)
            }
        }.padding(.vertical, 8)
    }

    @ViewBuilder
    private var timingDescription: some View {
        if session.stoppedAt != nil && task.phase == .waiting {
            Text("Not started before the run stopped").font(.callout).foregroundStyle(.secondary)
        } else { switch task.phase {
        case .waiting:
            Label(timing.isDue ? "Ready to start" : "Start in \(TimeText.duration(timing.plannedStart.timeIntervalSince(now)))",
                  systemImage: timing.isDue ? "play.circle.fill" : "clock")
                .foregroundStyle(timing.isDue ? Color.orange : Color.primary)
            estimate(prefix: "Estimated finish")
        case .running:
            Text(timing.isOvertime ? "Time elapsed — confirm Done when ready" : "\(TimeText.duration(timing.remainingSeconds)) remaining")
                .font(.title3.monospacedDigit()).foregroundStyle(timing.isOvertime ? Color.orange : Color.primary)
            if !timing.isOvertime { estimate(prefix: "Estimated finish") }
        case .paused:
            Text("Paused · \(TimeText.duration(timing.remainingSeconds)) remaining").monospacedDigit()
            estimate(prefix: "Finish if resumed now")
        case .completed:
            if let ended = task.endedAt {
                Label("Confirmed done at \(TimeText.fullDate(ended))", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
            }
            if let offset = timing.completionOffsetSeconds {
                Text(TimeText.offset(offset)).font(.caption).foregroundStyle(.secondary)
            }
        case .skipped:
            Text("Excluded from this run's completion count").font(.caption).foregroundStyle(.secondary)
        } }
    }

    @ViewBuilder
    private var controls: some View {
        if task.phase == .waiting {
            Button("Start") { act(.start) }.tint(.indigo)
        } else if task.phase == .running {
            Button("Pause") { act(.pause) }
        } else if task.phase == .paused {
            Button("Resume") { act(.resume) }.tint(.indigo)
        }
        Button("Done") { act(.complete) }.tint(.green)
            .accessibilityLabel("Confirm \(task.definition.title) is done")
        Menu {
            Button("Skip Task", role: .destructive) { act(.skip) }
        } label: { Label("More", systemImage: "ellipsis") }
    }

    @ViewBuilder
    private func estimate(prefix: String) -> some View {
        if let estimate = timing.estimatedFinish {
            Text("\(prefix) \(TimeText.clock(estimate)) · \(TimeText.offset(estimate.timeIntervalSince(session.commonFinish)))")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    private func act(_ action: RunAction) { store.act(action, sessionID: session.id, taskID: task.id) }
}
