import Foundation

enum QuickCommandRegistry {
    static func items(context: QuickCommandContext) -> [QuickCommandItem] {
        var items = navigationItems
        items.append(contentsOf: actionItems(context: context))

        items.append(contentsOf: context.projects.map { project in
            QuickCommandItem(
                id: "project:\(project.name)",
                kind: .project,
                title: project.name,
                subtitle: projectSubtitle(project),
                systemImage: "folder.fill",
                keywords: [project.name, "projet"],
                aliases: [],
                availability: .available,
                intent: .openProject(project.name)
            )
        })

        items.append(contentsOf: context.skills.map { skill in
            QuickCommandItem(
                id: skill.id,
                kind: .skill,
                title: skill.name,
                subtitle: "\(skill.project) · \(skill.status)",
                systemImage: "wand.and.stars",
                keywords: [skill.name, skill.project, skill.status],
                aliases: [],
                availability: .available,
                intent: .revealSkill(project: skill.project, skill: skill.name)
            )
        })

        items.append(contentsOf: context.activities.map { activity in
            QuickCommandItem(
                id: "activity:\(activity.id.uuidString)",
                kind: .activity,
                title: activity.receipt?.headline ?? activity.displayName,
                subtitle: [activity.targetDescription, activity.summary]
                    .filter { !$0.isEmpty }
                    .joined(separator: " · "),
                systemImage: activity.status.symbolName,
                keywords: [
                    activity.displayName,
                    activity.targetDescription,
                    activity.summary,
                    activity.receipt?.headline ?? ""
                ],
                aliases: [],
                availability: .available,
                intent: .openActivity(activity.id)
            )
        })

        items.append(contentsOf: resourceItems)
        return items
    }

    private static let navigationItems: [QuickCommandItem] = [
        QuickCommandItem(
            id: "navigation:overview",
            kind: .navigation,
            title: "Vue d’ensemble",
            subtitle: "État global du système",
            systemImage: AppSection.overview.symbolName,
            keywords: ["vue d’ensemble", "overview", "dashboard", "accueil"],
            aliases: ["home"],
            availability: .available,
            intent: .navigate(.overview)
        ),
        QuickCommandItem(
            id: "navigation:projects",
            kind: .navigation,
            title: "Projets",
            subtitle: "Projets et skills gérés",
            systemImage: AppSection.projects.symbolName,
            keywords: ["projets", "project", "skills"],
            aliases: [],
            availability: .available,
            intent: .navigate(.projects)
        ),
        QuickCommandItem(
            id: "navigation:activity",
            kind: .navigation,
            title: "Activité",
            subtitle: "Résultats de cette session",
            systemImage: AppSection.activity.symbolName,
            keywords: ["activité", "activity", "journal", "log"],
            aliases: [],
            availability: .available,
            intent: .navigate(.activity)
        )
    ]

    private static func actionItems(context: QuickCommandContext) -> [QuickCommandItem] {
        let syncAvailability: QuickCommandAvailability = context.operationIsRunning
            ? .unavailable("Une opération est déjà en cours.")
            : context.selectedProjectName == nil
                ? .unavailable("Sélectionnez d’abord un projet.")
                : .available

        var actions = [
            QuickCommandItem(
                id: "action:check",
                kind: .action,
                title: "Vérifier le système",
                subtitle: "Actualiser l’état global",
                systemImage: "checkmark.shield",
                keywords: ["vérifier", "verification", "check", "santé", "système"],
                aliases: ["health", "refresh"],
                availability: context.operationIsRunning
                    ? .unavailable("Une opération est déjà en cours.")
                    : .available,
                intent: .runCheck
            ),
            QuickCommandItem(
                id: "action:add-project",
                kind: .action,
                title: "Ajouter un projet",
                subtitle: "Déclarer un nouveau dossier",
                systemImage: "folder.badge.plus",
                keywords: ["ajouter", "projet", "add", "new"],
                aliases: [],
                availability: .available,
                intent: .addProject
            ),
            QuickCommandItem(
                id: "action:settings",
                kind: .action,
                title: "Ouvrir les réglages",
                subtitle: "Ressources, intégrations et avancé",
                systemImage: "gearshape",
                keywords: ["réglages", "settings", "préférences"],
                aliases: ["preferences"],
                availability: .available,
                intent: .openSettings
            )
        ]

        let syncProject = context.selectedProjectName
        actions.insert(
            QuickCommandItem(
                id: syncProject.map { "action:sync:\($0)" } ?? "action:sync:selected",
                kind: .action,
                title: syncProject.map { "Synchroniser \($0)" }
                    ?? "Synchroniser le projet sélectionné",
                subtitle: "Préparer la synchronisation du projet",
                systemImage: "arrow.triangle.2.circlepath",
                keywords: ["synchroniser", "sync", "export"] + (syncProject.map { [$0] } ?? []),
                aliases: [],
                availability: syncAvailability,
                intent: .prepareProjectSync(syncProject ?? "")
            ),
            at: 1
        )
        return actions
    }

    private static let resourceItems: [QuickCommandItem] = [
        QuickCommandItem(
            id: "resource:inventory",
            kind: .resource,
            title: "Ouvrir Inventory",
            subtitle: "État des projets et des skills",
            systemImage: "shippingbox",
            keywords: ["inventory", "inventaire", "rapport"],
            aliases: [],
            availability: .available,
            intent: .openResource("open-inventory")
        ),
        QuickCommandItem(
            id: "resource:doctor",
            kind: .resource,
            title: "Ouvrir Doctor",
            subtitle: "Diagnostic et anomalies",
            systemImage: "stethoscope",
            keywords: ["doctor", "diagnostic", "rapport"],
            aliases: [],
            availability: .available,
            intent: .openResource("open-doctor")
        ),
        QuickCommandItem(
            id: "resource:log",
            kind: .resource,
            title: "Ouvrir le dernier journal",
            subtitle: "Sortie technique de la dernière opération",
            systemImage: "doc.text.magnifyingglass",
            keywords: ["log", "journal", "sortie", "technique"],
            aliases: [],
            availability: .available,
            intent: .openResource("open-log")
        ),
        QuickCommandItem(
            id: "resource:readme",
            kind: .resource,
            title: "Ouvrir le README",
            subtitle: "Documentation du dépôt AI System",
            systemImage: "doc.text",
            keywords: ["readme", "documentation", "dépôt"],
            aliases: [],
            availability: .available,
            intent: .openResource("open-readme")
        ),
        QuickCommandItem(
            id: "resource:operations",
            kind: .resource,
            title: "Ouvrir le guide des opérations",
            subtitle: "Documentation AI System",
            systemImage: "book",
            keywords: ["operations", "opérations", "documentation", "guide"],
            aliases: [],
            availability: .available,
            intent: .openResource("open-operations")
        )
    ]

    private static func projectSubtitle(_ project: OverviewProject) -> String {
        switch project.state {
        case .healthy: return "À jour"
        case .attention, .error:
            let count = project.summary.actionRequired
            return count == 1 ? "1 élément à examiner" : "\(count) éléments à examiner"
        case .unknown: return "Non vérifié"
        case .disabled: return "Désactivé"
        }
    }
}
