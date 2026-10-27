import Foundation

struct ExportCopy: Identifiable {
    let id: UUID
    let directory: URL
    let file: URL
}

enum DataExport {
    static func prepare(data: Data, name: String = "Conductor.json") throws -> ExportCopy {
        let copy = try makeCopy(name: name)
        do { try data.write(to: copy.file, options: .withoutOverwriting); return copy }
        catch { throw cleanup(copy, after: error) }
    }

    static func prepare(original: URL) throws -> ExportCopy {
        let copy = try makeCopy(name: "Conductor-original.json")
        do { try FileManager.default.copyItem(at: original, to: copy.file); return copy }
        catch { throw cleanup(copy, after: error) }
    }

    private static func makeCopy(name: String) throws -> ExportCopy {
        let id = UUID()
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Conductor-export-\(id.uuidString)", isDirectory: true)
        guard !FileManager.default.fileExists(atPath: directory.path) else {
            throw CocoaError(.fileWriteFileExists)
        }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: false)
        return ExportCopy(id: id, directory: directory, file: directory.appendingPathComponent(name))
    }

    static func remove(_ copy: ExportCopy) throws {
        let expected = FileManager.default.temporaryDirectory
            .appendingPathComponent("Conductor-export-\(copy.id.uuidString)", isDirectory: true).standardizedFileURL
        guard copy.directory.standardizedFileURL == expected else { throw CocoaError(.fileWriteNoPermission) }
        try FileManager.default.removeItem(at: copy.directory)
    }

    private static func cleanup(_ copy: ExportCopy, after preparationError: Error) -> Error {
        do { try remove(copy); return preparationError }
        catch {
            return CocoaError(.fileWriteUnknown, userInfo: [NSLocalizedDescriptionKey:
                "Export preparation failed: \(preparationError.localizedDescription). Its temporary folder could not be removed: \(copy.directory.lastPathComponent). \(error.localizedDescription)"])
        }
    }
}
