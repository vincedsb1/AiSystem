import AppKit
import Observation
import SwiftUI

// MARK: - Settings shell

/// Réglages — everything secondary, relocated out of the main navigation.
///
/// No global log panel lives here (spec 16.3): each action gives its own inline
/// feedback and nothing leaks into the other sections.
struct SettingsView: View {
    var body: some View {
        TabView {
            LocationsSettings()
                .tabItem { Label("Emplacements", systemImage: "folder") }

            IntegrationsSettings()
                .tabItem { Label("Intégrations", systemImage: "app.connected.to.app.below.fill") }

            ResourcesSettings()
                .tabItem { Label("Ressources", systemImage: "book") }

            AdvancedSettings()
                .tabItem { Label("Avancé", systemImage: "wrench.and.screwdriver") }
        }
        .frame(width: 560, height: 420)
    }
}

// MARK: - Shared action feedback

/// Inline, section-scoped feedback. Never propagated to another section.
@MainActor
@Observable
final class SettingsActionRunner {
    private(set) var isRunning = false
    private(set) var message: String?
    private(set) var succeeded = true

    private let service: ProjectSkillsService

    init(service: ProjectSkillsService = ProjectSkillsService()) {
        self.service = service
    }

    func run(_ action: String, successMessage: String) async {
        guard !isRunning else { return }
        isRunning = true
        message = nil
        defer { isRunning = false }

        let result = await service.openResource(action)
        succeeded = result.succeeded
        if result.succeeded {
            message = successMessage
        } else {
            // The last stderr line is more useful than the exit code alone
            // (FR-STATE-02).
            let detail = result.stderr
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .components(separatedBy: .newlines)
                .last ?? ""
            message = detail.isEmpty
                ? "L'action n'a pas pu être effectuée."
                : detail
        }
    }

    func clear() { message = nil }
}

private struct ActionFeedback: View {
    let runner: SettingsActionRunner

    var body: some View {
        if let message = runner.message {
            InlineFeedbackView(
                type: runner.succeeded ? .success : .error,
                message: message,
                actionLabel: "Masquer",
                action: { runner.clear() }
            )
        }
    }
}

// MARK: - Locations

private struct LocationsSettings: View {
    var body: some View {
        Form {
            Section {
                LocationRow(label: "Racine AI System", path: AISystemPaths.root)
                LocationRow(label: "Dossier des logs", path: AISystemPaths.logsDir)
                LocationRow(label: "Application installée", path: Self.installedAppPath)
            } header: {
                Text("Emplacements")
            } footer: {
                // These paths are hardcoded today. Migrating them to dynamic
                // configuration is deliberately not part of this redesign
                // (spec 16.2); they are surfaced, not changed.
                Text("Ces chemins sont fixes dans cette version.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    private static var installedAppPath: String {
        NSHomeDirectory() + "/Applications/AI System.app"
    }
}

private struct LocationRow: View {
    let label: String
    let path: String

    @State private var missing = false

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                Text(path)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                    .lineLimit(2)
                    .truncationMode(.middle)

                if missing {
                    Text("Emplacement introuvable.")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Spacer()

            Button("Ouvrir") { reveal() }
                .controlSize(.small)
        }
        .padding(.vertical, 2)
    }

    private func reveal() {
        guard FileManager.default.fileExists(atPath: path) else {
            missing = true
            return
        }
        missing = false
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: path)
    }
}

// MARK: - Integrations

private struct IntegrationsSettings: View {
    @State private var runner = SettingsActionRunner()

    private var cursorAvailable: Bool {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.todesktop.230313mzl4w4u92")
            != nil
            || FileManager.default.fileExists(atPath: "/Applications/Cursor.app")
    }

    var body: some View {
        Form {
            Section("Ouvrir le dépôt AI System") {
                HStack {
                    Text("Finder")
                    Spacer()
                    Button("Ouvrir") {
                        Task { await runner.run("open-finder", successMessage: "Finder ouvert.") }
                    }
                    .controlSize(.small)
                }

                HStack {
                    Text("Terminal")
                    Spacer()
                    Button("Ouvrir") {
                        Task { await runner.run("open-terminal", successMessage: "Terminal ouvert.") }
                    }
                    .controlSize(.small)
                }

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Cursor")
                        if !cursorAvailable {
                            Text("Cursor n'est pas installé sur cette machine.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Button("Ouvrir") {
                        Task { await runner.run("open-cursor", successMessage: "Cursor ouvert.") }
                    }
                    .controlSize(.small)
                    .disabled(!cursorAvailable)
                }
            }

            if runner.message != nil {
                Section { ActionFeedback(runner: runner) }
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Resources

private struct ResourcesSettings: View {
    @State private var runner = SettingsActionRunner()

    private let documents: [(String, String)] = [
        ("README", "open-readme"),
        ("Operations", "open-operations"),
        ("Skill Workflow", "open-skill-workflow"),
        ("Project Onboarding", "open-project-onboarding"),
        ("Local GUI Design", "open-local-gui-design"),
        ("Plan AI System", "open-plan")
    ]

    var body: some View {
        Form {
            Section("Rapports") {
                resourceRow("Inventory", action: "open-inventory")
                resourceRow("Doctor", action: "open-doctor")
                resourceRow("Dernier log", action: "open-log")
            }

            Section("Documentation") {
                ForEach(documents, id: \.0) { document in
                    resourceRow(document.0, action: document.1)
                }
            }

            if runner.message != nil {
                Section { ActionFeedback(runner: runner) }
            }
        }
        .formStyle(.grouped)
    }

    private func resourceRow(_ label: String, action: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Button("Ouvrir") {
                Task { await runner.run(action, successMessage: "\(label) ouvert.") }
            }
            .controlSize(.small)
            .disabled(runner.isRunning)
        }
    }
}

// MARK: - Advanced

private struct AdvancedSettings: View {
    @State private var runner = SettingsActionRunner()
    @State private var confirmRebuild = false

    var body: some View {
        Form {
            Section("Dépôt") {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Hook pre-commit")
                        Text("Installe la validation locale avant chaque commit.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Installer") {
                        Task {
                            await runner.run("install-hooks", successMessage: "Hook installé.")
                        }
                    }
                    .controlSize(.small)
                    .disabled(runner.isRunning)
                }

                HStack {
                    Text("État Git")
                    Spacer()
                    Button("Afficher") {
                        Task { await runner.run("git-status", successMessage: "État Git affiché.") }
                    }
                    .controlSize(.small)
                    .disabled(runner.isRunning)
                }
            }

            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Reconstruire l'application")
                        Text("Recompile et réinstalle AI System.app.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Reconstruire") { confirmRebuild = true }
                        .controlSize(.small)
                        .disabled(runner.isRunning)
                }
            } header: {
                Text("Maintenance")
            } footer: {
                Text("Ces actions sont rares et modifient l'installation locale.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("À propos") {
                LabeledContent("Version", value: Self.appVersion)
                LabeledContent("Backend", value: "project_skills / project_actions v1")
            }

            if runner.message != nil {
                Section { ActionFeedback(runner: runner) }
            }
        }
        .formStyle(.grouped)
        // A rare action with a real local impact is confirmed (spec 17.4).
        .confirmationDialog(
            "Reconstruire l'application ?",
            isPresented: $confirmRebuild,
            titleVisibility: .visible
        ) {
            Button("Reconstruire") {
                Task {
                    await runner.run(
                        "build-swift-app",
                        successMessage: "Application reconstruite et installée."
                    )
                }
            }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("L'application installée dans ~/Applications sera remplacée.")
        }
    }

    private static var appVersion: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "—"
        let build = info?["CFBundleVersion"] as? String ?? "—"
        return "\(short) (\(build))"
    }
}
