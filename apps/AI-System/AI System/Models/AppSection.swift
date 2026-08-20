import Foundation
import SwiftUI

// MARK: - App Navigation Structure

/// The three main navigation destinations for the refactored AI System app.
enum AppSection: String, CaseIterable, Identifiable, Codable {
    case overview
    case projects
    case activity

    var id: String { rawValue }

    /// Localized display name for the sidebar.
    var displayName: String {
        switch self {
        case .overview:
            return "Vue d'ensemble"
        case .projects:
            return "Projets"
        case .activity:
            return "Activité"
        }
    }

    /// SF Symbol for sidebar icon.
    var symbolName: String {
        switch self {
        case .overview:
            return "square.grid.2x2.fill"
        case .projects:
            return "folder.fill"
        case .activity:
            return "list.bullet.rectangle.fill"
        }
    }

    /// Navigation title for the detail area.
    var navigationTitle: String {
        displayName
    }

    /// Sort order in sidebar (if needed for specific ordering).
    var sortOrder: Int {
        switch self {
        case .overview:
            return 0
        case .projects:
            return 1
        case .activity:
            return 2
        }
    }
}
