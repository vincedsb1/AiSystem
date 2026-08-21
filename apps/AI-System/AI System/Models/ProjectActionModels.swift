import Foundation

// MARK: - Action Response (contract: project_actions.py)

/// Result of a mutating backend action (import or sync).
///
/// `writeState` is the field that lets the interface state whether anything
/// was modified, which every error message must answer (spec 17.3).
struct ProjectActionResponse: Codable, Equatable, VersionedBackendPayload {
    let schemaVersion: Int
    let status: String
    let generatedAt: String
    let action: String
    let project: String?
    let skill: String?
    let outcome: ActionOutcome
    let writeState: ActionWriteState
    let summary: String
    let changes: ActionChanges?
    let error: BackendError?

    var succeeded: Bool { status == "ok" }
}

enum ActionOutcome: String, Codable, Equatable {
    case imported
    case added
    case alreadyManaged = "already_managed"
    case synced
    case planned
    case partial
    case failed

    /// Whether the outcome should read as a success to the user.
    var isSuccess: Bool {
        switch self {
        case .imported, .added, .alreadyManaged, .synced, .planned:
            return true
        case .partial, .failed:
            return false
        }
    }
}

enum ActionWriteState: String, Codable, Equatable {
    case noChanges = "no_changes"
    case applied
    case partialChanges = "partial_changes"
    case rolledBack = "rolled_back"

    /// Sentence describing what happened to the files, shown on failure.
    var description: String {
        switch self {
        case .noChanges: return "Aucune modification n'a été effectuée."
        case .applied: return "Les modifications ont été appliquées."
        case .partialChanges: return "Certaines modifications ont été appliquées."
        case .rolledBack: return "Les modifications ont été annulées."
        }
    }
}

struct ActionChanges: Codable, Equatable {
    let created: Int
    let updated: Int
    let unchanged: Int
    let conflicts: Int?
    let canonicalId: String?
    let canonicalPath: String?
    let targets: [String]?
    let applied: Bool?
    let blocked: [BlockedSkill]?

    var hasChanges: Bool { created > 0 || updated > 0 }

    init(
        created: Int,
        updated: Int,
        unchanged: Int,
        conflicts: Int? = nil,
        canonicalId: String? = nil,
        canonicalPath: String? = nil,
        targets: [String]? = nil,
        applied: Bool? = nil,
        blocked: [BlockedSkill]? = nil
    ) {
        self.created = created
        self.updated = updated
        self.unchanged = unchanged
        self.conflicts = conflicts
        self.canonicalId = canonicalId
        self.canonicalPath = canonicalPath
        self.targets = targets
        self.applied = applied
        self.blocked = blocked
    }

    enum CodingKeys: String, CodingKey {
        case created, updated, unchanged, conflicts
        case canonicalId, canonicalPath, targets, applied, blocked
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        created = try container.decodeIfPresent(Int.self, forKey: .created) ?? 0
        updated = try container.decodeIfPresent(Int.self, forKey: .updated) ?? 0
        unchanged = try container.decodeIfPresent(Int.self, forKey: .unchanged) ?? 0
        conflicts = try container.decodeIfPresent(Int.self, forKey: .conflicts)
        canonicalId = try container.decodeIfPresent(String.self, forKey: .canonicalId)
        canonicalPath = try container.decodeIfPresent(String.self, forKey: .canonicalPath)
        applied = try container.decodeIfPresent(Bool.self, forKey: .applied)
        blocked = try container.decodeIfPresent([BlockedSkill].self, forKey: .blocked)

        // `targets` is a string array on import and an object array on sync.
        if let names = try? container.decodeIfPresent([String].self, forKey: .targets) {
            targets = names
        } else {
            targets = nil
        }
    }
}

struct BlockedSkill: Codable, Equatable, Identifiable {
    let skill: String
    let status: SkillStatus

    var id: String { skill }
}

// MARK: - Import source

enum ImportSource: String, Codable, CaseIterable, Identifiable {
    case codex
    case claude

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .codex: return "Codex"
        case .claude: return "Claude"
        }
    }
}

// MARK: - Per-skill operation state

/// Tracks the operation running on one skill so a second submission is
/// impossible and only that row shows progress (spec 22.3).
enum SkillOperationState: Equatable {
    case idle
    case running
    case succeeded(String)
    case failed(String)

    var isRunning: Bool { self == .running }
}
