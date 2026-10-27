import ConductorCore
import Foundation

enum AppTab: Hashable { case plans, run, settings }

struct PlanEditorContext: Identifiable {
    let id = UUID()
    let original: TaskPlan?
}

struct RunSetupContext: Identifiable {
    let id = UUID()
    let plan: TaskPlan
    let existingSession: RunSession?
}

enum AppSheet: Identifiable {
    case plan(PlanEditorContext)
    case run(RunSetupContext)

    var id: UUID {
        switch self {
        case .plan(let context): return context.id
        case .run(let context): return context.id
        }
    }
}

struct AppNotice {
    let message: String
    let isError: Bool
}

struct CandidateSaveError: Error, LocalizedError {
    let message: String
    let candidateData: Data
    var errorDescription: String? { message }
}

struct DraftTask: Identifiable {
    var id: UUID
    var title: String
    var hours: Int
    var minutes: Int
    var seconds: Int

    init(_ definition: TaskDefinition? = nil) {
        id = definition?.id ?? UUID()
        title = definition?.title ?? ""
        let duration = definition?.durationSeconds ?? 300
        hours = duration / 3600
        minutes = duration % 3600 / 60
        seconds = duration % 60
    }

    var definition: TaskDefinition {
        TaskDefinition(id: id, title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                       durationSeconds: hours * 3600 + minutes * 60 + seconds)
    }
}
