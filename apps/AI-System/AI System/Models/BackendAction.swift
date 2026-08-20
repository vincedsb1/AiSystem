import Foundation

enum SidebarSection: String, CaseIterable, Identifiable {
    case dashboard, diffusion, projects, reports, documentation, tools, logs

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .dashboard: return "Tableau de bord"
        case .diffusion: return "Diffusion"
        case .projects: return "Projets"
        case .reports: return "Rapports"
        case .documentation: return "Documentation"
        case .tools: return "Outils"
        case .logs: return "Logs"
        }
    }

    var symbolName: String {
        switch self {
        case .dashboard: return "square.grid.2x2"
        case .diffusion: return "arrow.triangle.2.circlepath"
        case .projects: return "folder"
        case .reports: return "doc.text"
        case .documentation: return "book"
        case .tools: return "wrench.and.screwdriver"
        case .logs: return "terminal"
        }
    }
}

enum BackendAction: String, CaseIterable, Identifiable {
    case check, inventory, doctor
    case update, updateCodex, updateClaude
    case openInventory, openDoctor, openLog
    case openReadme, openOperations, openSkillWorkflow
    case openProjectOnboarding, openPlan, openLocalGuiDesign
    case installHooks, gitStatus
    case openCursor, openTerminal, openFinder
    case buildGuiApp

    var id: String { rawValue }

    var cliArgument: String {
        switch self {
        case .check: return "check"
        case .inventory: return "inventory"
        case .doctor: return "doctor"
        case .update: return "update"
        case .updateCodex: return "update-codex"
        case .updateClaude: return "update-claude"
        case .openInventory: return "open-inventory"
        case .openDoctor: return "open-doctor"
        case .openLog: return "open-log"
        case .openReadme: return "open-readme"
        case .openOperations: return "open-operations"
        case .openSkillWorkflow: return "open-skill-workflow"
        case .openProjectOnboarding: return "open-project-onboarding"
        case .openPlan: return "open-plan"
        case .openLocalGuiDesign: return "open-local-gui-design"
        case .installHooks: return "install-hooks"
        case .gitStatus: return "git-status"
        case .openCursor: return "open-cursor"
        case .openTerminal: return "open-terminal"
        case .openFinder: return "open-finder"
        case .buildGuiApp: return "build-gui-app"
        }
    }

    var displayName: String {
        switch self {
        case .check: return "Vérifier le système"
        case .inventory: return "Lancer Inventory"
        case .doctor: return "Lancer Doctor"
        case .update: return "Diffuser partout"
        case .updateCodex: return "Diffuser Codex seulement"
        case .updateClaude: return "Diffuser Claude seulement"
        case .openInventory: return "Ouvrir Inventory"
        case .openDoctor: return "Ouvrir Doctor"
        case .openLog: return "Ouvrir le dernier log"
        case .openReadme: return "Ouvrir README"
        case .openOperations: return "Ouvrir Operations"
        case .openSkillWorkflow: return "Ouvrir Skill Workflow"
        case .openProjectOnboarding: return "Ouvrir Project Onboarding"
        case .openPlan: return "Ouvrir Plan AI System"
        case .openLocalGuiDesign: return "Ouvrir Local GUI Design"
        case .installHooks: return "Installer le hook pre-commit"
        case .gitStatus: return "Afficher l'état Git"
        case .openCursor: return "Ouvrir dans Cursor"
        case .openTerminal: return "Ouvrir dans Terminal"
        case .openFinder: return "Ouvrir dans Finder"
        case .buildGuiApp: return "Recréer l'app Dock"
        }
    }
}
