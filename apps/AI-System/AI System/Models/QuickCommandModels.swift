import Foundation

enum QuickCommandKind: String, CaseIterable, Equatable {
    case navigation
    case action
    case project
    case skill
    case activity
    case resource

    var displayName: String {
        switch self {
        case .navigation: return "Navigation"
        case .action: return "Actions"
        case .project: return "Projets"
        case .skill: return "Skills"
        case .activity: return "Activité"
        case .resource: return "Ressources"
        }
    }
}

enum QuickCommandAvailability: Equatable {
    case available
    case unavailable(String)

    var isAvailable: Bool {
        if case .available = self { return true }
        return false
    }

    var explanation: String? {
        if case .unavailable(let reason) = self { return reason }
        return nil
    }
}

enum QuickCommandIntent: Equatable {
    case navigate(AppSection)
    case openProject(String)
    case revealSkill(project: String, skill: String)
    case openActivity(UUID)
    case runCheck
    case prepareProjectSync(String)
    case addProject
    case openResource(String)
    case openSettings
}

struct QuickCommandItem: Identifiable, Equatable {
    let id: String
    let kind: QuickCommandKind
    let title: String
    let subtitle: String
    let systemImage: String
    let keywords: [String]
    let aliases: [String]
    let availability: QuickCommandAvailability
    let intent: QuickCommandIntent
}

struct QuickCommandSkillRecord: Identifiable, Equatable {
    let project: String
    let name: String
    let status: String

    var id: String { "skill:\(project):\(name)" }
}

struct QuickCommandSkillSelection: Equatable {
    let project: String
    let skill: String
}

struct QuickCommandContext {
    let activeSection: AppSection
    let selectedProjectName: String?
    let projects: [OverviewProject]
    let skills: [QuickCommandSkillRecord]
    let activities: [Activity]
    let operationIsRunning: Bool
}
