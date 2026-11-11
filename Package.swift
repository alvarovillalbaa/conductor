// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Conductor",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "ConductorCore", targets: ["ConductorCore"])],
    targets: [
        .target(name: "ConductorCore"),
        .target(name: "ConductorFileStore", dependencies: ["ConductorCore"],
                path: "App/Conductor/Services", exclude: ["DataExport.swift", "ReminderService.swift"],
                sources: ["WorkspaceFileStore.swift"]),
        .testTarget(name: "ConductorCoreTests", dependencies: ["ConductorCore"]),
        .testTarget(name: "ConductorFileStoreTests", dependencies: ["ConductorFileStore", "ConductorCore"]),
    ]
)
