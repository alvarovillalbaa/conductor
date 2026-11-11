import ConductorCore
@testable import ConductorFileStore
import Foundation
import XCTest

final class WorkspaceFileStoreTests: XCTestCase {
    private func fixture() throws -> URL {
        let manager = FileManager.default
        let parent = ProcessInfo.processInfo.environment["CONDUCTOR_STORAGE_TEST_ROOT"]
            .map { URL(fileURLWithPath: $0, isDirectory: true) } ?? manager.temporaryDirectory
        let directory = parent.appendingPathComponent("ConductorFileStoreTests-\(UUID().uuidString)", isDirectory: true)
        try manager.createDirectory(at: directory, withIntermediateDirectories: false)
        addTeardownBlock { try manager.removeItem(at: directory) }
        return directory
    }

    func testMissingParentLoadsEmptyWithoutWriting() throws {
        let directory = try fixture()
        let parent = directory.appendingPathComponent("NotCreated", isDirectory: true)
        let store = WorkspaceFileStore(fileURL: parent.appendingPathComponent("workspace.json"))
        XCTAssertEqual(try store.load(), Workspace())
        XCTAssertFalse(FileManager.default.fileExists(atPath: parent.path))
    }

    func testMissingFileLoadsEmptyWithoutWriting() throws {
        let directory = try fixture()
        let file = directory.appendingPathComponent("workspace.json")
        XCTAssertEqual(try WorkspaceFileStore(fileURL: file).load(), Workspace())
        XCTAssertFalse(FileManager.default.fileExists(atPath: file.path))
    }

    func testSavedWorkspaceReloadsWithoutChangingBytes() throws {
        let directory = try fixture()
        let file = directory.appendingPathComponent("Conductor/workspace.json")
        let store = WorkspaceFileStore(fileURL: file)
        let workspace = Workspace(remindersEnabled: true)
        let data = try WorkspaceCodec.encode(workspace)
        try store.save(data)
        XCTAssertEqual(try store.load(), workspace)
        XCTAssertEqual(try Data(contentsOf: file), data)
    }

    func testMalformedFileRemainsRecoverable() throws {
        let file = try fixture().appendingPathComponent("workspace.json")
        let original = Data("{authored invalid workspace".utf8)
        try original.write(to: file)
        XCTAssertThrowsError(try WorkspaceFileStore(fileURL: file).load())
        XCTAssertEqual(try Data(contentsOf: file), original)
    }

    func testOversizedFileRemainsRecoverable() throws {
        let file = try fixture().appendingPathComponent("workspace.json")
        let original = Data(repeating: 0x20, count: WorkspaceCodec.maximumBytes + 1)
        try original.write(to: file)
        XCTAssertThrowsError(try WorkspaceFileStore(fileURL: file).load())
        XCTAssertEqual(try Data(contentsOf: file), original)
    }

    func testDirectoryAtFilePathIsNotTreatedAsNewWorkspace() throws {
        let file = try fixture().appendingPathComponent("workspace.json", isDirectory: true)
        try FileManager.default.createDirectory(at: file, withIntermediateDirectories: false)
        let sentinel = file.appendingPathComponent("keep.txt")
        let original = Data("authored recovery sentinel".utf8)
        try original.write(to: sentinel)
        XCTAssertThrowsError(try WorkspaceFileStore(fileURL: file).load())
        XCTAssertEqual(try Data(contentsOf: sentinel), original)
    }

    func testUnavailableDirectoryFails() {
        XCTAssertThrowsError(try WorkspaceFileStore(fileURL: nil).load())
    }
}
