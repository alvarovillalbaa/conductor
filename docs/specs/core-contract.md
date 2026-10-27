# Shared core/app API

ConductorCore is a Foundation-only library. The iOS app imports it as a local Swift package. Public value models are Codable/Hashable/Sendable where appropriate, with public member initializers. Stored properties below are public mutable values so a candidate copy can be edited and validated before persistence. UUID defaults use UUID(); dates default only where sensible. Additional private helpers/errors are allowed; coordinate public API changes.

```swift
public struct TaskDefinition: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    public var title: String
    public var durationSeconds: Int
}
public struct TaskPlan: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    public var title: String
    public var tasks: [TaskDefinition]
    public var revision: Int
    public var updatedAt: Date
}
public enum TaskPhase: String, Codable, Sendable { case waiting, running, paused, completed, skipped }
public struct RunTask: Codable, Identifiable, Hashable, Sendable {
    public var definition: TaskDefinition
    public var phase: TaskPhase
    public var elapsedBeforeRun: TimeInterval
    public var runningSince: Date?
    public var firstStartedAt: Date?
    public var endedAt: Date?
    public var id: UUID { definition.id }
}
public struct RunSession: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    public var plan: TaskPlan
    public var commonFinish: Date
    public var createdAt: Date
    public var stoppedAt: Date?
    public var tasks: [RunTask]
}
public struct Workspace: Codable, Hashable, Sendable {
    public var version: Int // 1
    public var plans: [TaskPlan]
    public var session: RunSession?
    public var remindersEnabled: Bool
    public init(version: Int = 1, plans: [TaskPlan] = [], session: RunSession? = nil, remindersEnabled: Bool = false)
}
public enum RunAction: Sendable { case start, pause, resume, complete, skip }
public struct TaskTiming: Sendable {
    public let plannedStart: Date
    public let elapsedSeconds: TimeInterval
    public let remainingSeconds: TimeInterval
    public let estimatedFinish: Date?
    public let isDue: Bool
    public let isOvertime: Bool
    public let completionOffsetSeconds: TimeInterval?
}
public struct ReminderCue: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let body: String
    public let fireAt: Date
}
public enum ScheduleEngine {
    public static let maximumPlans: Int // 50
    public static let maximumTasks: Int // 20
    public static let maximumDurationSeconds: Int // 86400
    public static func validate(_ workspace: Workspace) throws
    public static func validate(_ plan: TaskPlan) throws
    public static func earliestFinish(for plan: TaskPlan, now: Date) throws -> Date
    public static func start(plan: TaskPlan, finishAt: Date, now: Date) throws -> RunSession
    public static func applying(_ action: RunAction, to session: RunSession, taskID: UUID, now: Date) throws -> RunSession
    public static func stop(_ session: RunSession, now: Date) throws -> RunSession
    public static func isActive(_ session: RunSession) -> Bool
    public static func timing(for task: RunTask, in session: RunSession, now: Date) -> TaskTiming
    public static func reminders(for session: RunSession, now: Date) -> [ReminderCue]
}
public enum WorkspaceCodec {
    public static let maximumBytes: Int // 2000000
    public static func encode(_ workspace: Workspace) throws -> Data
    public static func decode(_ data: Data) throws -> Workspace
}
```

Validation is complete, never filtering: version1, <=50 plans; each plan has a unique ID, nonblank title <=80 characters and4,096UTF-8bytes, revision>=0 and 1...20 tasks with unique IDs/nonblank titles under the same bounds and durations1...86400. Dates must be finite and within epoch1970...year3000, elapsed values finite/nonnegative, run states structurally consistent, frozen task definitions bijective with the snapshot plan. Empty new workspaces are valid. Unknown JSON fields/versions, duplicate IDs/JSON field names and malformed states fail decoding without destroying original bytes. Native backups are UTF-8 JSON with optional UTF-8 BOM. The codec uses numeric millisecond dates and the same byte cap for encode/decode.

Shared finish must be >=now+longest duration and <=now+7days. Planned start is commonFinish-duration. Waiting/running/paused/terminal states are explicit. Start only waiting; pause only running; resume only paused; complete/skip any nonterminal state. Terminal/stopped runs reject further actions. Pause/stop accumulate elapsed running time, clamp backward-clock deltas to zero, and do not make automatic completion claims. Stop converts running tasks to paused and sets stoppedAt. Completed/skipped tasks use endedAt; user-confirmed completion may exist without firstStartedAt. Clock changes can reorder observed dates, so don't invent timestamps just to enforce chronology.

Timing: waiting estimate is commonFinish until late, then now+duration; running/paused estimate is now+remaining (paused means 'if resumed now'); completed estimate is endedAt; skipped has none. A stopped run has no estimate for unfinished tasks, whose remaining time stays frozen. Remaining is clamped at zero; overtime must not mark completion. A stopped run has no start cues. Reminders include only future cues for active runs: one per waiting start or running elapsed estimate, plus the shared target if future. No repeated replay of past cues; IDs include run/task identity. This bounds the app to at most21 future cues.

The app must persist a validated candidate before UI success/reminder changes. Active runs are frozen snapshots independent of current saved plans. Validate run IDs and expected plan revisions at action/commit time. Notification reconciliation requires generation fencing around every await; unique operation-qualified request IDs ensure late cleanup cannot delete a newer request with the same logical cue.
