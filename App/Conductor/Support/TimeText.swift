import ConductorCore
import Foundation

enum TimeText {
    static func duration(_ seconds: TimeInterval) -> String {
        guard seconds.isFinite else { return "Unavailable" }
        let positive = max(0, seconds)
        guard positive <= 31_536_000 else { return "More than a year" }
        let whole = Int(ceil(positive))
        let hours = whole / 3600, minutes = whole % 3600 / 60, remainder = whole % 60
        if hours > 0 { return "\(hours)h \(minutes)m \(remainder)s" }
        if minutes > 0 { return "\(minutes)m \(remainder)s" }
        return "\(remainder)s"
    }

    static func clock(_ date: Date) -> String { date.formatted(date: .omitted, time: .standard) }
    static func fullDate(_ date: Date) -> String { date.formatted(date: .abbreviated, time: .standard) }

    static func offset(_ seconds: TimeInterval) -> String {
        guard seconds.isFinite else { return "Timing unavailable" }
        if abs(seconds) < 1 { return "At the target" }
        return seconds > 0 ? "\(duration(seconds)) after target" : "\(duration(-seconds)) before target"
    }

    static func phase(_ phase: TaskPhase) -> String {
        switch phase {
        case .waiting: return "Waiting"
        case .running: return "Running"
        case .paused: return "Paused"
        case .completed: return "Done"
        case .skipped: return "Skipped"
        }
    }
}
