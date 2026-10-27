import Foundation

public struct TaskDefinition: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    public var title: String
    public var durationSeconds: Int

    public init(id: UUID = UUID(), title: String, durationSeconds: Int) {
        self.id = id
        self.title = title
        self.durationSeconds = durationSeconds
    }
}

public struct TaskPlan: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    public var title: String
    public var tasks: [TaskDefinition]
    public var revision: Int
    public var updatedAt: Date

    public init(id: UUID = UUID(), title: String, tasks: [TaskDefinition], revision: Int = 0, updatedAt: Date = Date()) {
        self.id = id
        self.title = title
        self.tasks = tasks
        self.revision = revision
        self.updatedAt = updatedAt
    }
}

public enum TaskPhase: String, Codable, Hashable, Sendable {
    case waiting, running, paused, completed, skipped
}

public struct RunTask: Codable, Identifiable, Hashable, Sendable {
    public var definition: TaskDefinition
    public var phase: TaskPhase
    public var elapsedBeforeRun: TimeInterval
    public var runningSince: Date?
    public var firstStartedAt: Date?
    public var endedAt: Date?
    public var id: UUID { definition.id }

    public init(definition: TaskDefinition, phase: TaskPhase = .waiting, elapsedBeforeRun: TimeInterval = 0,
                runningSince: Date? = nil, firstStartedAt: Date? = nil, endedAt: Date? = nil) {
        self.definition = definition
        self.phase = phase
        self.elapsedBeforeRun = elapsedBeforeRun
        self.runningSince = runningSince
        self.firstStartedAt = firstStartedAt
        self.endedAt = endedAt
    }
}

public struct RunSession: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    public var plan: TaskPlan
    public var commonFinish: Date
    public var createdAt: Date
    public var stoppedAt: Date?
    public var tasks: [RunTask]

    public init(id: UUID = UUID(), plan: TaskPlan, commonFinish: Date, createdAt: Date,
                stoppedAt: Date? = nil, tasks: [RunTask]) {
        self.id = id
        self.plan = plan
        self.commonFinish = commonFinish
        self.createdAt = createdAt
        self.stoppedAt = stoppedAt
        self.tasks = tasks
    }
}

public struct Workspace: Codable, Hashable, Sendable {
    public var version: Int
    public var plans: [TaskPlan]
    public var session: RunSession?
    public var remindersEnabled: Bool

    public init(version: Int = 1, plans: [TaskPlan] = [], session: RunSession? = nil, remindersEnabled: Bool = false) {
        self.version = version
        self.plans = plans
        self.session = session
        self.remindersEnabled = remindersEnabled
    }
}

public enum RunAction: Hashable, Sendable {
    case start, pause, resume, complete, skip
}

public struct TaskTiming: Sendable {
    public let plannedStart: Date
    public let elapsedSeconds: TimeInterval
    public let remainingSeconds: TimeInterval
    public let estimatedFinish: Date?
    public let isDue: Bool
    public let isOvertime: Bool
    public let completionOffsetSeconds: TimeInterval?

    public init(plannedStart: Date, elapsedSeconds: TimeInterval, remainingSeconds: TimeInterval,
                estimatedFinish: Date?, isDue: Bool, isOvertime: Bool, completionOffsetSeconds: TimeInterval?) {
        self.plannedStart = plannedStart
        self.elapsedSeconds = elapsedSeconds
        self.remainingSeconds = remainingSeconds
        self.estimatedFinish = estimatedFinish
        self.isDue = isDue
        self.isOvertime = isOvertime
        self.completionOffsetSeconds = completionOffsetSeconds
    }
}

public struct ReminderCue: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let body: String
    public let fireAt: Date

    public init(id: String, title: String, body: String, fireAt: Date) {
        self.id = id
        self.title = title
        self.body = body
        self.fireAt = fireAt
    }
}

public enum ConductorError: Error, LocalizedError, Equatable {
    case invalidPlan(String)
    case invalidRun(String)
    case invalidAction(String)
    case invalidData(String)

    public var errorDescription: String? {
        switch self {
        case .invalidPlan(let message), .invalidRun(let message), .invalidAction(let message), .invalidData(let message):
            return message
        }
    }
}
