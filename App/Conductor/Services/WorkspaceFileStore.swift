import ConductorCore
import Foundation

enum LocalDataError: Error, LocalizedError {
    case unavailableDirectory
    case oversized
    case recoveryRequired
    case changedPlan
    case changedRun
    case revisionLimit

    var errorDescription: String? {
        switch self {
        case .unavailableDirectory: return "The app's local data folder is unavailable. Your existing file was not replaced."
        case .oversized: return "The saved file is larger than Conductor can safely open. Export the original file before repairing it."
        case .recoveryRequired: return "Saved data needs recovery. Export the original or try loading again before making changes."
        case .changedPlan: return "This plan changed since you opened it. Your draft is still here; reopen the latest plan before replacing it."
        case .changedRun: return "This run has changed. Return to the current run before using this action."
        case .revisionLimit: return "This plan's revision cannot be advanced safely. Keep or export the draft as a new plan."
        }
    }
}

struct WorkspaceFileStore {
    let fileURL: URL?

    init() {
        fileURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("Conductor", isDirectory: true)
            .appendingPathComponent("workspace.json")
    }

    func load() throws -> Workspace {
        guard let fileURL else { throw LocalDataError.unavailableDirectory }
        let handle: FileHandle
        do { handle = try FileHandle(forReadingFrom: fileURL) }
        catch let error as CocoaError where error.code == .fileReadNoSuchFile { return Workspace() }
        defer { try? handle.close() }
        var data = Data()
        while data.count <= WorkspaceCodec.maximumBytes {
            let remaining = WorkspaceCodec.maximumBytes + 1 - data.count
            guard remaining > 0 else { break }
            let chunk = try handle.read(upToCount: min(65_536, remaining)) ?? Data()
            if chunk.isEmpty { break }
            data.append(chunk)
        }
        guard data.count <= WorkspaceCodec.maximumBytes else { throw LocalDataError.oversized }
        return try WorkspaceCodec.decode(data)
    }

    func save(_ data: Data) throws {
        guard let fileURL else { throw LocalDataError.unavailableDirectory }
        guard data.count <= WorkspaceCodec.maximumBytes else { throw LocalDataError.oversized }
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: fileURL, options: .atomic)
    }
}
