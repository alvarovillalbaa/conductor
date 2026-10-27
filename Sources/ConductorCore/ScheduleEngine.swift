import Foundation

public enum ScheduleEngine {
    public static let maximumPlans = 50
    public static let maximumTasks = 20
    public static let maximumDurationSeconds = 86_400
    static let maximumHorizonSeconds: TimeInterval = 7 * 24 * 60 * 60

    public static func earliestFinish(for plan: TaskPlan, now: Date) throws -> Date {
        try validate(plan)
        try validateDate(now)
        let duration = plan.tasks.map(\.durationSeconds).max() ?? 0
        let finish = now.addingTimeInterval(TimeInterval(duration))
        try validateDate(finish)
        return finish
    }

    public static func start(plan: TaskPlan, finishAt: Date, now: Date) throws -> RunSession {
        let earliest = try earliestFinish(for: plan, now: now)
        try validateDate(finishAt)
        guard finishAt >= earliest else {
            throw ConductorError.invalidRun("That finish time leaves too little time. Choose a later target or start the longest task now.")
        }
        guard finishAt <= now.addingTimeInterval(maximumHorizonSeconds) else {
            throw ConductorError.invalidRun("Choose a shared finish within the next seven days.")
        }
        let session = RunSession(plan: plan, commonFinish: finishAt, createdAt: now,
                                 tasks: plan.tasks.map { RunTask(definition: $0) })
        try validateSession(session)
        return session
    }

    public static func applying(_ action: RunAction, to session: RunSession, taskID: UUID, now: Date) throws -> RunSession {
        try validateSession(session)
        try validateDate(now)
        guard isActive(session) else { throw ConductorError.invalidAction("This run has ended. Start a new run to continue.") }
        guard let index = session.tasks.firstIndex(where: { $0.id == taskID }) else {
            throw ConductorError.invalidAction("That task is no longer part of this run.")
        }
        var result = session
        var task = result.tasks[index]
        guard !isTerminal(task.phase) else { throw ConductorError.invalidAction("This task has already ended.") }

        switch action {
        case .start:
            guard task.phase == .waiting else { throw ConductorError.invalidAction("Only a waiting task can be started.") }
            task.phase = .running
            task.runningSince = now
            task.firstStartedAt = now
        case .pause:
            guard task.phase == .running else { throw ConductorError.invalidAction("Only a running task can be paused.") }
            task.elapsedBeforeRun = elapsed(task, at: now)
            task.runningSince = nil
            task.phase = .paused
        case .resume:
            guard task.phase == .paused else { throw ConductorError.invalidAction("Only a paused task can be resumed.") }
            task.runningSince = now
            task.phase = .running
        case .complete, .skip:
            task.elapsedBeforeRun = elapsed(task, at: now)
            task.runningSince = nil
            task.endedAt = now
            task.phase = action == .complete ? .completed : .skipped
        }
        result.tasks[index] = task
        try validateSession(result)
        return result
    }

    public static func stop(_ session: RunSession, now: Date) throws -> RunSession {
        try validateSession(session)
        try validateDate(now)
        guard isActive(session) else { throw ConductorError.invalidAction("This run has already ended.") }
        var result = session
        result.tasks = session.tasks.map { original in
            guard original.phase == .running else { return original }
            var task = original
            task.elapsedBeforeRun = elapsed(original, at: now)
            task.runningSince = nil
            task.phase = .paused
            return task
        }
        result.stoppedAt = now
        try validateSession(result)
        return result
    }

    public static func isActive(_ session: RunSession) -> Bool {
        session.stoppedAt == nil && session.tasks.contains { !isTerminal($0.phase) }
    }

    public static func timing(for task: RunTask, in session: RunSession, now: Date) -> TaskTiming {
        let plannedStart = session.commonFinish.addingTimeInterval(-TimeInterval(task.definition.durationSeconds))
        let elapsedSeconds = elapsed(task, at: now)
        let terminal = isTerminal(task.phase)
        let remaining = terminal ? 0 : max(0, TimeInterval(task.definition.durationSeconds) - elapsedSeconds)
        let estimated: Date?
        if task.phase == .completed {
            estimated = task.endedAt
        } else if task.phase == .skipped || session.stoppedAt != nil {
            estimated = nil
        } else if task.phase == .waiting {
            estimated = max(now, plannedStart).addingTimeInterval(TimeInterval(task.definition.durationSeconds))
        } else {
            estimated = now.addingTimeInterval(remaining)
        }
        return TaskTiming(plannedStart: plannedStart, elapsedSeconds: elapsedSeconds, remainingSeconds: remaining,
            estimatedFinish: estimated,
            isDue: isActive(session) && task.phase == .waiting && now >= plannedStart,
            isOvertime: !terminal && task.phase != .waiting && elapsedSeconds >= TimeInterval(task.definition.durationSeconds),
            completionOffsetSeconds: task.phase == .completed ? task.endedAt?.timeIntervalSince(session.commonFinish) : nil)
    }

    static func elapsed(_ task: RunTask, at now: Date) -> TimeInterval {
        guard task.phase == .running, let since = task.runningSince else { return task.elapsedBeforeRun }
        return task.elapsedBeforeRun + max(0, now.timeIntervalSince(since))
    }
}
