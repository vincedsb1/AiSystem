import Foundation
import Observation

/// Presentation cache shared by Overview, Projects and Quick Command.
/// It contains only already-loaded structured responses; it never triggers a
/// filesystem scan or a backend call when the command palette opens.
@MainActor
@Observable
final class AppDataStore {
    private(set) var overview: SystemOverviewResponse?
    private(set) var projectScans: [String: ScanProjectResponse] = [:]
    var activeSection: AppSection = .overview
    var selectedProjectName: String?

    func updateOverview(_ payload: SystemOverviewResponse) {
        overview = payload
    }

    func updateScan(_ payload: ScanProjectResponse, for project: String) {
        projectScans[project] = payload
    }

    var projects: [OverviewProject] {
        overview?.projects ?? []
    }

    var skills: [QuickCommandSkillRecord] {
        projectScans.flatMap { project, scan in
            scan.skills.map {
                QuickCommandSkillRecord(
                    project: project,
                    name: $0.name,
                    status: $0.status.displayName
                )
            }
        }
        .sorted {
            if $0.project != $1.project {
                return $0.project.localizedCaseInsensitiveCompare($1.project) == .orderedAscending
            }
            return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }
}
