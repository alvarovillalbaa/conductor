import ConductorCore
import Foundation
import UserNotifications

struct ReminderUpdate: Sendable {
    let permission: String
    let scheduledCount: Int
    let message: String
    let isError: Bool
}

actor ReminderService {
    private let center = UNUserNotificationCenter.current()
    private let prefix = "conductor."
    private var operationID = UUID()

    func requestAccess() async throws -> Bool {
        try Task.checkCancellation()
        return try await center.requestAuthorization(options: [.alert, .sound])
    }

    func reconcile(cues: [ReminderCue], enabled: Bool) async -> ReminderUpdate? {
        // A canceled caller must not supersede a newer desired state on actor entry.
        guard !Task.isCancelled else { return nil }
        let operation = UUID()
        operationID = operation
        let pending = await center.pendingNotificationRequests()
        guard current(operation) else { return nil }
        center.removePendingNotificationRequests(withIdentifiers: pending.map(\.identifier).filter { $0.hasPrefix(prefix) })
        let settings = await center.notificationSettings()
        guard current(operation) else { return nil }
        let permission = permissionText(settings.authorizationStatus)
        guard enabled else {
            return ReminderUpdate(permission: permission, scheduledCount: 0,
                                  message: "Conductor reminders are off.", isError: false)
        }
        guard [.authorized, .provisional, .ephemeral].contains(settings.authorizationStatus) else {
            return ReminderUpdate(permission: permission, scheduledCount: 0,
                                  message: "iOS has not allowed reminders. Live start cues remain available in the app.", isError: true)
        }
        var accepted: [String] = []
        for cue in cues {
            guard current(operation) else { remove(accepted); return nil }
            let interval = cue.fireAt.timeIntervalSinceNow
            guard interval > 0 else { continue }
            let identifier = prefix + operation.uuidString + "." + cue.id
            let content = UNMutableNotificationContent()
            content.title = cue.title
            content.body = cue.body
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, interval), repeats: false)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            do {
                try await center.add(request)
                guard current(operation) else { remove(accepted + [identifier]); return nil }
                accepted.append(identifier)
            } catch {
                remove(accepted + [identifier])
                guard current(operation) else { return nil }
                return ReminderUpdate(permission: permission, scheduledCount: 0,
                                      message: "Reminders could not be scheduled: \(error.localizedDescription)", isError: true)
            }
        }
        return ReminderUpdate(permission: permission, scheduledCount: accepted.count,
                              message: "Requested \(accepted.count) future cues. iOS may delay or suppress delivery.", isError: false)
    }

    private func current(_ value: UUID) -> Bool { operationID == value && !Task.isCancelled }
    private func remove(_ identifiers: [String]) {
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
    }
    private func permissionText(_ value: UNAuthorizationStatus) -> String {
        switch value {
        case .notDetermined: return "Not requested"
        case .denied: return "Not allowed"
        case .authorized: return "Allowed"
        case .provisional: return "Quiet delivery"
        case .ephemeral: return "Temporary access"
        @unknown default: return "Unknown"
        }
    }
}
