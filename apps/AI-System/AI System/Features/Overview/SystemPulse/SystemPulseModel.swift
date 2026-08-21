import Foundation

enum SystemPulseNodeKind: String, CaseIterable, Identifiable {
    case core
    case projects
    case claude
    case codex

    var id: String { rawValue }
}

struct SystemPulseNodeModel: Identifiable, Equatable {
    let id: SystemPulseNodeKind
    let title: String
    let subtitle: String
    let state: SystemState
    let symbolName: String
    let isInteractive: Bool

    var accessibilityLabel: String {
        "\(title). \(subtitle). \(state.title)."
    }
}

/// Pure presentation mapping for the System Pulse. It consumes only the
/// structured overview already loaded by the app and never infers provider
/// state from logs or paths.
struct SystemPulseModel: Equatable {
    let state: SystemState
    let nodes: [SystemPulseNodeModel]
    let accessibilitySummary: String

    init(overview: SystemOverviewResponse?, state: SystemState, isRunning: Bool) {
        let effectiveState = isRunning ? .checking : state
        let summary = overview?.summary

        let coreSubtitle = summary.map {
            "\($0.skillsManaged) skills gérés"
        } ?? "Skills non vérifiés"

        let projectTitle: String
        let projectSubtitle: String
        if let summary {
            projectTitle = "\(summary.projectsTotal) \(summary.projectsTotal == 1 ? "projet" : "projets")"
            if summary.actionRequired > 0 {
                projectSubtitle = "\(summary.actionRequired) à examiner"
            } else {
                projectSubtitle = "\(summary.projectsHealthy) à jour"
            }
        } else {
            projectTitle = "Projets"
            projectSubtitle = "État non vérifié"
        }

        let providerSubtitle: String
        switch effectiveState {
        case .healthy: providerSubtitle = "Synchronisé · état global"
        case .attention: providerSubtitle = "À examiner · état global"
        case .error: providerSubtitle = "Erreur · état global"
        case .checking: providerSubtitle = "Vérification en cours…"
        case .unknown: providerSubtitle = "État non vérifié"
        }

        self.state = effectiveState
        self.nodes = [
            SystemPulseNodeModel(
                id: .core,
                title: "AI System",
                subtitle: coreSubtitle,
                state: effectiveState,
                symbolName: "circle.hexagongrid.fill",
                isInteractive: false
            ),
            SystemPulseNodeModel(
                id: .projects,
                title: projectTitle,
                subtitle: projectSubtitle,
                state: effectiveState,
                symbolName: "folder.fill",
                isInteractive: true
            ),
            SystemPulseNodeModel(
                id: .claude,
                title: "Claude",
                subtitle: providerSubtitle,
                state: effectiveState,
                symbolName: "text.bubble.fill",
                isInteractive: true
            ),
            SystemPulseNodeModel(
                id: .codex,
                title: "Codex",
                subtitle: providerSubtitle,
                state: effectiveState,
                symbolName: "terminal.fill",
                isInteractive: true
            )
        ]

        self.accessibilitySummary = Self.summary(
            overview: overview,
            state: effectiveState
        )
    }

    private static func summary(
        overview: SystemOverviewResponse?,
        state: SystemState
    ) -> String {
        guard let summary = overview?.summary else {
            return "AI System. État non vérifié. Vérifiez maintenant."
        }

        switch state {
        case .healthy:
            return "AI System est à jour. "
                + "\(summary.projectsTotal) \(summary.projectsTotal == 1 ? "projet est" : "projets sont") "
                + "synchronisés avec Claude et Codex. Aucune action n’est requise."
        case .attention:
            return "AI System. \(summary.actionRequired) "
                + "\(summary.actionRequired == 1 ? "élément demande" : "éléments demandent") "
                + "votre attention. Ouvrez Projets pour examiner le contexte."
        case .error:
            return "AI System. La vérification a rencontré une erreur. "
                + "Ouvrez Activité pour consulter le résultat."
        case .checking:
            return "AI System vérifie \(summary.projectsTotal) projets. "
                + "La navigation reste disponible."
        case .unknown:
            return "AI System. État non vérifié. Vérifiez maintenant."
        }
    }
}
