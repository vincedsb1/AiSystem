import SwiftUI

// MARK: - Spacing scale (spec 18.2)

/// Shared spacing scale. A coherent base, not a rule that every measurement
/// must be frozen.
enum Spacing {
    /// 4 pt — micro spacing inside a single control.
    static let micro: CGFloat = 4
    /// 8 pt — closely related elements.
    static let related: CGFloat = 8
    /// 12 pt — controls belonging to one group.
    static let grouped: CGFloat = 12
    /// 16 pt — standard padding.
    static let standard: CGFloat = 16
    /// 24 pt — separation between sections.
    static let sectionGap: CGFloat = 24
    /// 32 pt — major breaks.
    static let major: CGFloat = 32
}

// MARK: - Semantic tints (spec 18.4)

/// Colours always accompany a label or a symbol; they never carry meaning
/// alone (FR-STATE-03).
extension SystemState {
    var tint: Color {
        switch self {
        case .unknown: return .secondary
        case .checking: return .accentColor
        case .healthy: return .green
        case .attention: return .orange
        case .error: return .red
        }
    }
}

extension ProjectState {
    var tint: Color {
        switch self {
        case .unknown: return .secondary
        case .healthy: return .green
        case .attention: return .orange
        case .error: return .red
        case .disabled: return .secondary
        }
    }
}

extension OperationStatus {
    var tint: Color {
        switch self {
        case .queued: return .secondary
        case .running: return .accentColor
        case .succeeded: return .green
        case .partiallySucceeded: return .orange
        case .failed: return .red
        case .cancelled: return .secondary
        }
    }
}

extension SkillStatus {
    var tint: Color {
        switch self {
        case .managedSynced:
            return .green
        case .expectedClaudeOnly, .expectedCodexOnly:
            return .secondary
        case .conflict, .manifestError:
            return .red
        default:
            return .orange
        }
    }
}

extension ActionSeverity {
    var tint: Color {
        switch self {
        case .attention: return .orange
        case .error: return .red
        }
    }
}
