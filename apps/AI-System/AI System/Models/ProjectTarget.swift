import Foundation

enum ProjectTarget: String, CaseIterable, Identifiable {
    case codex, claude, both

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .codex: return "Codex seulement"
        case .claude: return "Claude seulement"
        case .both: return "Claude + Codex"
        }
    }

    var backendValue: String {
        rawValue
    }
}
