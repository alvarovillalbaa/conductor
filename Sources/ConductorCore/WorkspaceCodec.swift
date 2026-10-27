import Foundation

public enum WorkspaceCodec {
    public static let maximumBytes = 2_000_000

    public static func encode(_ workspace: Workspace) throws -> Data {
        try ScheduleEngine.validate(workspace)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(workspace)
        guard data.count <= maximumBytes else {
            throw ConductorError.invalidData("The workspace exceeds the two-megabyte storage limit.")
        }
        return data
    }

    public static func decode(_ data: Data) throws -> Workspace {
        guard data.count <= maximumBytes else {
            throw ConductorError.invalidData("The saved file is too large. Keep the original file for recovery.")
        }
        do {
            // Raw NUL is invalid UTF-8 JSON and can otherwise trigger Foundation's
            // automatic interpretation of BOM-less UTF-16/UTF-32 input.
            guard !data.contains(0), String(data: data, encoding: .utf8) != nil else {
                throw ConductorError.invalidData("The saved workspace must be UTF-8 JSON. Keep the original file for recovery.")
            }
            let input = data.starts(with: [0xef, 0xbb, 0xbf]) ? Data(data.dropFirst(3)) : data
            let object = try JSONSerialization.jsonObject(with: input)
            try JSONKeyUniqueness.validate(input)
            try WorkspaceShape.validate(object)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .millisecondsSince1970
            let workspace = try decoder.decode(Workspace.self, from: input)
            try ScheduleEngine.validate(workspace)
            return workspace
        } catch let error as ConductorError {
            throw error
        } catch {
            throw ConductorError.invalidData("The saved workspace is unsupported or incomplete. Keep the original file for recovery.")
        }
    }
}

private enum WorkspaceShape {
    static func validate(_ value: Any) throws {
        let object = try dictionary(value, allowed: ["version", "plans", "session", "remindersEnabled"])
        if let plans = object["plans"] as? [Any] {
            guard plans.count <= ScheduleEngine.maximumPlans else {
                throw ConductorError.invalidData("The workspace has too many plans.")
            }
            for plan in plans { try validatePlan(plan) }
        }
        if let session = nonnull(object["session"]) { try validateSession(session) }
    }

    private static func validatePlan(_ value: Any) throws {
        let object = try dictionary(value, allowed: ["id", "title", "tasks", "revision", "updatedAt"])
        if let tasks = object["tasks"] as? [Any] {
            guard tasks.count <= ScheduleEngine.maximumTasks else {
                throw ConductorError.invalidData("The plan has too many tasks.")
            }
            for task in tasks { try validateDefinition(task) }
        }
    }

    private static func validateDefinition(_ value: Any) throws {
        _ = try dictionary(value, allowed: ["id", "title", "durationSeconds"])
    }

    private static func validateSession(_ value: Any) throws {
        let object = try dictionary(value, allowed: ["id", "plan", "commonFinish", "createdAt", "stoppedAt", "tasks"])
        if let plan = object["plan"] { try validatePlan(plan) }
        if let tasks = object["tasks"] as? [Any] {
            guard tasks.count <= ScheduleEngine.maximumTasks else {
                throw ConductorError.invalidData("The run has too many tasks.")
            }
            for task in tasks {
                let taskObject = try dictionary(task, allowed: ["definition", "phase", "elapsedBeforeRun", "runningSince", "firstStartedAt", "endedAt"])
                if let definition = taskObject["definition"] { try validateDefinition(definition) }
            }
        }
    }

    private static func dictionary(_ value: Any, allowed: Set<String>) throws -> [String: Any] {
        guard let object = value as? [String: Any] else {
            throw ConductorError.invalidData("The saved workspace contains an unsupported record.")
        }
        guard Set(object.keys).isSubset(of: allowed) else {
            throw ConductorError.invalidData("The saved workspace contains unsupported fields. Keep the original file for recovery.")
        }
        return object
    }

    private static func nonnull(_ value: Any?) -> Any? {
        guard let value, !(value is NSNull) else { return nil }
        return value
    }
}
