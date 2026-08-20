import Foundation

// MARK: - Activity

/// A contextualised record of one operation triggered from the app.
///
/// Persistence decision (spec 14.2): **session-only**. The spec calls this the
/// simplest acceptable starting point provided the last log file stays
/// reachable, which it does through the backend's `open-log` route. No
/// structured backend history exists today, and inventing an Application
/// Support store would add scope without a contract to back it.
struct Activity: Identifiable, Equatable {
    let id: UUID
    let kind: ActivityKind
    let displayName: String
    let scope: ActivityScope
    var status: OperationStatus
    let startedAt: Date
    var finishedAt: Date?
    var summary: String
    var changes: ActionChanges?
    var warningCount: Int
    var error: ActivityError?
    var technical: TechnicalDetails?

    init(
        id: UUID = UUID(),
        kind: ActivityKind,
        displayName: String,
        scope: ActivityScope,
        status: OperationStatus = .running,
        startedAt: Date = Date(),
        finishedAt: Date? = nil,
        summary: String = "",
        changes: ActionChanges? = nil,
        warningCount: Int = 0,
        error: ActivityError? = nil,
        technical: TechnicalDetails? = nil
    ) {
        self.id = id
        self.kind = kind
        self.displayName = displayName
        self.scope = scope
        self.status = status
        self.startedAt = startedAt
        self.finishedAt = finishedAt
        self.summary = summary
        self.changes = changes
        self.warningCount = warningCount
        self.error = error
        self.technical = technical
    }

    var duration: TimeInterval? {
        guard let finishedAt else { return nil }
        return finishedAt.timeIntervalSince(startedAt)
    }

    var projectId: String? {
        switch scope {
        case .project(let name): return name
        case .skill(let project, _): return project
        case .global, .tool: return nil
        }
    }

    var skillId: String? {
        if case .skill(_, let skill) = scope { return skill }
        return nil
    }

    /// Target shown in the list, in business terms.
    var targetDescription: String {
        switch scope {
        case .global: return "Système"
        case .project(let name): return name
        case .skill(let project, let skill): return "\(project) · \(skill)"
        case .tool: return "Outil"
        }
    }

    var durationDescription: String? {
        guard let duration else { return nil }
        return AppFormatters.duration(duration)
    }
}

// MARK: - Kind

enum ActivityKind: String, Equatable, CaseIterable {
    case check
    case scan
    case importSkill
    case sync
    case addProject
    case tool

    var displayName: String {
        switch self {
        case .check: return "Vérification"
        case .scan: return "Analyse"
        case .importSkill: return "Import"
        case .sync: return "Synchronisation"
        case .addProject: return "Ajout de projet"
        case .tool: return "Outil"
        }
    }

    var symbolName: String {
        switch self {
        case .check: return "checkmark.shield"
        case .scan: return "magnifyingglass"
        case .importSkill: return "tray.and.arrow.down"
        case .sync: return "arrow.triangle.2.circlepath"
        case .addProject: return "folder.badge.plus"
        case .tool: return "wrench.and.screwdriver"
        }
    }
}

// MARK: - Scope

enum ActivityScope: Equatable {
    case global
    case project(String)
    case skill(String, String)
    case tool
}

// MARK: - Error

struct ActivityError: Equatable {
    let code: String?
    let message: String
    let writeState: ActionWriteState?
    let retryable: Bool

    /// Failure copy always answers "was anything modified?" (spec 17.3).
    var writeStateDescription: String? { writeState?.description }
}

// MARK: - Technical details

/// Everything an engineer needs, kept collapsed by default (FR-ACT-02) and the
/// only place monospaced type is used (FR-ACT-01).
struct TechnicalDetails: Equatable {
    let action: String
    let arguments: [String]
    let exitCode: Int32
    let duration: TimeInterval
    let stdout: String
    let stderr: String
    let logPath: String

    /// Single block copied by "Copier les détails". No secret is added that the
    /// backend did not already emit (FR-ACT-03).
    var copyableText: String {
        var lines: [String] = []
        lines.append("Action : \(action)")
        if !arguments.isEmpty {
            lines.append("Arguments : \(arguments.joined(separator: " "))")
        }
        lines.append("Code de sortie : \(exitCode)")
        lines.append(String(format: "Durée : %.3f s", duration))
        lines.append("Log : \(logPath)")
        if !stdout.isEmpty {
            lines.append("\n--- stdout ---\n\(stdout)")
        }
        if !stderr.isEmpty {
            lines.append("\n--- stderr ---\n\(stderr)")
        }
        return lines.joined(separator: "\n")
    }
}

// MARK: - Filter

enum ActivityFilter: String, CaseIterable, Identifiable {
    case all
    case failures
    case checks
    case syncs

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .all: return "Toutes"
        case .failures: return "Échecs"
        case .checks: return "Vérifications"
        case .syncs: return "Synchronisations"
        }
    }

    func matches(_ activity: Activity) -> Bool {
        switch self {
        case .all:
            return true
        case .failures:
            return activity.status == .failed || activity.status == .partiallySucceeded
        case .checks:
            return activity.kind == .check || activity.kind == .scan
        case .syncs:
            return activity.kind == .sync || activity.kind == .importSkill
        }
    }
}
