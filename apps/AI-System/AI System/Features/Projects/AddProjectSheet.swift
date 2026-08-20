import AppKit
import Observation
import SwiftUI

// MARK: - Models

/// Contract of `project_actions.py inspect-folder`.
struct FolderInspection: Codable, Equatable, VersionedBackendPayload {
    let schemaVersion: Int
    let status: String
    let generatedAt: String
    let path: String
    let suggestedName: String
    let detectedTargets: [String]
    let proposedTargets: [String]
    let alreadyRegistered: RegisteredProject?
    let defaultInstallNow: Bool
    let error: BackendError?
}

struct RegisteredProject: Codable, Equatable {
    let name: String?
    let enabled: Bool
    let reason: String

    var explanation: String {
        switch reason {
        case "same_root":
            return "Ce dossier est déjà déclaré comme projet."
        default:
            return "Un projet porte déjà ce nom."
        }
    }
}

// MARK: - View model

@MainActor
@Observable
final class AddProjectViewModel {
    private let service: ProjectSkillsService

    private(set) var inspection: FolderInspection?
    private(set) var isInspecting = false
    private(set) var isSubmitting = false
    private(set) var errorMessage: String?

    var name = ""
    var targets: Set<String> = ["codex"]

    /// Set once the project has been added, so the caller can select it.
    private(set) var addedProjectName: String?

    init(service: ProjectSkillsService = ProjectSkillsService()) {
        self.service = service
    }

    var selectedPath: String? { inspection?.path }

    var isBlocked: Bool { inspection?.alreadyRegistered != nil }

    var canSubmit: Bool {
        inspection != nil
            && !isBlocked
            && !name.trimmingCharacters(in: .whitespaces).isEmpty
            && !targets.isEmpty
            && !isSubmitting
            && !isInspecting
    }

    /// Native folder chooser (spec 13.2). Cancelling leaves the form untouched.
    func chooseFolder() async {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Choisir"
        panel.message = "Sélectionnez le dossier du projet"

        guard panel.runModal() == .OK, let url = panel.url else { return }
        await inspect(path: url.path)
    }

    func inspect(path: String) async {
        guard !isInspecting else { return }
        isInspecting = true
        defer { isInspecting = false }

        switch await service.inspectFolder(path: path) {
        case .success(let payload):
            inspection = payload
            // The name is prefilled but stays editable (spec 13.3).
            name = payload.suggestedName
            targets = Set(payload.proposedTargets)
            errorMessage = payload.alreadyRegistered?.explanation
        case .failure(let error):
            inspection = nil
            errorMessage = error.errorDescription
        }
    }

    func submit() async {
        guard canSubmit, let path = selectedPath else { return }
        isSubmitting = true
        defer { isSubmitting = false }

        let trimmed = name.trimmingCharacters(in: .whitespaces)
        switch await service.addProject(name: trimmed, path: path, targets: targets) {
        case .success(let response):
            if response.succeeded {
                addedProjectName = response.project ?? trimmed
                errorMessage = nil
            } else {
                errorMessage = response.summary
            }
        case .failure(let error):
            // Every error states whether the project was added (spec 13.4).
            errorMessage = Self.message(for: error)
        }
    }

    private static func message(for error: ProjectSkillsServiceError) -> String {
        let reason = error.errorDescription ?? "Erreur inconnue."
        guard case .backend(let backendError) = error,
              let raw = backendError.writeState,
              let state = ActionWriteState(rawValue: raw)
        else { return reason }
        return "\(reason) \(state.description)"
    }

    func toggle(target: String) {
        if targets.contains(target) {
            guard targets.count > 1 else { return }
            targets.remove(target)
        } else {
            targets.insert(target)
        }
    }
}

// MARK: - Sheet

/// Guided project creation, replacing the permanent technical form.
struct AddProjectSheet: View {
    @State private var model = AddProjectViewModel()

    let onCancel: () -> Void
    let onAdded: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.standard) {
            Text("Ajouter un projet")
                .font(.title3)
                .fontWeight(.semibold)

            folderField

            if model.inspection != nil {
                Divider()
                nameField
                targetsField
            }

            if let message = model.errorMessage {
                InlineFeedbackView(
                    type: model.isBlocked ? .warning : .error,
                    message: message
                )
            }

            Divider()
            buttons
        }
        .padding(Spacing.sectionGap)
        .frame(minWidth: 480, maxWidth: 560)
        .onChange(of: model.addedProjectName) { _, name in
            guard let name else { return }
            onAdded(name)
        }
    }

    // MARK: Fields

    private var folderField: some View {
        VStack(alignment: .leading, spacing: Spacing.related) {
            Text("Dossier du projet")
                .font(.headline)

            HStack(spacing: Spacing.grouped) {
                Button("Choisir un dossier…") {
                    Task { await model.chooseFolder() }
                }
                .disabled(model.isInspecting || model.isSubmitting)

                if model.isInspecting {
                    ProgressView().controlSize(.small)
                }
            }

            if let path = model.selectedPath {
                Text(path)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                    .lineLimit(2)
                    .truncationMode(.middle)
            } else {
                Text("Aucun dossier sélectionné")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: Spacing.related) {
            Text("Nom")
                .font(.headline)

            TextField("Nom du projet", text: $model.name)
                .textFieldStyle(.roundedBorder)
                .disabled(model.isSubmitting)
                .accessibilityLabel("Nom du projet")
        }
    }

    private var targetsField: some View {
        VStack(alignment: .leading, spacing: Spacing.related) {
            Text("Environnements")
                .font(.headline)

            if let detected = model.inspection?.detectedTargets, !detected.isEmpty {
                Text("Détectés dans le dossier : \(detected.map(label).joined(separator: ", ")).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Aucun environnement détecté ; Codex est proposé par défaut.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: Spacing.standard) {
                ForEach(["codex", "claude"], id: \.self) { target in
                    Toggle(label(target), isOn: Binding(
                        get: { model.targets.contains(target) },
                        set: { _ in model.toggle(target: target) }
                    ))
                    .disabled(model.isSubmitting)
                }
            }
        }
    }

    private func label(_ target: String) -> String {
        target == "claude" ? "Claude" : "Codex"
    }

    private var buttons: some View {
        HStack {
            Button("Annuler", role: .cancel, action: onCancel)
                .keyboardShortcut(.cancelAction)
                .disabled(model.isSubmitting)

            Spacer()

            Button {
                Task { await model.submit() }
            } label: {
                if model.isSubmitting {
                    HStack(spacing: Spacing.related) {
                        ProgressView().controlSize(.small)
                        Text("Ajout en cours…")
                    }
                } else {
                    Text("Ajouter le projet")
                }
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)
            .disabled(!model.canSubmit)
        }
    }
}
