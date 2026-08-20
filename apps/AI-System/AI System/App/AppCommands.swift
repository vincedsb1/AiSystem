import SwiftUI

/// Menu commands and keyboard shortcuts (spec 19.1).
///
/// The shortcuts are posted as notifications so a destination reacts only when
/// it is the one on screen. ⌘, is provided by the Settings scene itself.
struct AppCommands: Commands {
    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("Nouveau projet…") {
                NotificationCenter.default.post(name: .addProjectRequested, object: nil)
            }
            .keyboardShortcut("n", modifiers: .command)
        }

        CommandGroup(after: .toolbar) {
            Button("Actualiser") {
                NotificationCenter.default.post(name: .refreshRequested, object: nil)
            }
            .keyboardShortcut("r", modifiers: .command)

            Button("Rechercher") {
                NotificationCenter.default.post(name: .searchRequested, object: nil)
            }
            .keyboardShortcut("f", modifiers: .command)
        }

        CommandGroup(replacing: .help) {
            Button("Documentation AI System") {
                Task { await ProjectSkillsService().openResource("open-readme") }
            }
            Button("Guide des opérations") {
                Task { await ProjectSkillsService().openResource("open-operations") }
            }
        }
    }
}

extension Notification.Name {
    static let addProjectRequested = Notification.Name("ai.system.addProjectRequested")
    static let refreshRequested = Notification.Name("ai.system.refreshRequested")
    static let searchRequested = Notification.Name("ai.system.searchRequested")
}
