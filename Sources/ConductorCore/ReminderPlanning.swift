import Foundation

extension ScheduleEngine {
    public static func reminders(for session: RunSession, now: Date) -> [ReminderCue] {
        do { try validateSession(session); try validateDate(now) }
        catch { return [] }
        guard isActive(session) else { return [] }
        let prefix = session.id.uuidString.lowercased()
        var cues: [ReminderCue] = []
        for task in session.tasks {
            let timing = timing(for: task, in: session, now: now)
            let taskID = task.id.uuidString.lowercased()
            if task.phase == .waiting && timing.plannedStart > now {
                cues.append(ReminderCue(id: "\(prefix).\(taskID).start", title: "Start \(task.definition.title)",
                    body: "Your planned start time for \(session.plan.title).", fireAt: timing.plannedStart))
            } else if task.phase == .running && timing.remainingSeconds > 0, let finish = timing.estimatedFinish {
                cues.append(ReminderCue(id: "\(prefix).\(taskID).elapsed", title: "Time elapsed: \(task.definition.title)",
                    body: "Check the task and mark it done when it is actually complete.", fireAt: finish))
            }
        }
        if session.commonFinish > now {
            cues.append(ReminderCue(id: "\(prefix).target", title: "Shared finish time",
                body: "Check the tasks in \(session.plan.title).", fireAt: session.commonFinish))
        }
        return cues.sorted { $0.fireAt == $1.fireAt ? $0.id < $1.id : $0.fireAt < $1.fireAt }
    }
}
