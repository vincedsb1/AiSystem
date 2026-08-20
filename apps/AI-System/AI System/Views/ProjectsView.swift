import SwiftUI
import AppKit

struct ProjectsView: View {
    @Environment(CommandCenter.self) private var center

    @State private var projectName = ""
    @State private var projectTarget: ProjectTarget = .both

    @State private var newProjectName = ""
    @State private var newProjectPath = ""
    @State private var newProjectTarget: ProjectTarget = .both
    @State private var installNow = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Projets")
                    .font(.largeTitle.bold())

                RunStatusView(currentRun: center.currentRun, lastResult: center.lastResult)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Mettre à jour un projet existant")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Nom du projet")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("Ex: intrai", text: $projectName)
                            .textFieldStyle(.roundedBorder)

                        Text("Cible")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Picker("Cible", selection: $projectTarget) {
                            ForEach(ProjectTarget.allCases) { target in
                                Text(target.displayName).tag(target)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    PrimaryActionButton(
                        title: "Mettre à jour ce projet",
                        systemImage: "arrow.triangle.2.circlepath",
                        disabled: center.isRunning || projectName.trimmingCharacters(in: .whitespaces).isEmpty
                    ) {
                        await center.executeRaw(
                            action: "install-project",
                            displayName: "Mise à jour du projet",
                            args: [projectName, projectTarget.backendValue]
                        )
                    }

                    if let result = center.lastResult, projectName == lastActionProject {
                        ResultPanel(result: result)
                    }
                }
                .padding()
                .background(.quaternary.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 12) {
                    Text("Ajouter un nouveau projet")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Nom du projet")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("Ex: mon-projet", text: $newProjectName)
                            .textFieldStyle(.roundedBorder)

                        Text("Chemin absolu")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack(spacing: 8) {
                            TextField("Ex: /Users/username/Projects/mon-projet", text: $newProjectPath)
                                .textFieldStyle(.roundedBorder)
                            Button("Parcourir…") {
                                chooseFolder()
                            }
                        }

                        Text("Cible")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Picker("Cible", selection: $newProjectTarget) {
                            ForEach(ProjectTarget.allCases) { target in
                                Text(target.displayName).tag(target)
                            }
                        }
                        .pickerStyle(.segmented)

                        Toggle("Installer les commandes/skills maintenant", isOn: $installNow)
                            .font(.caption)
                    }

                    PrimaryActionButton(
                        title: "Ajouter le projet",
                        systemImage: "plus.circle",
                        disabled: center.isRunning || newProjectName.trimmingCharacters(in: .whitespaces).isEmpty || newProjectPath.trimmingCharacters(in: .whitespaces).isEmpty || !isAbsolutePath(newProjectPath)
                    ) {
                        await center.executeRaw(
                            action: "add-project",
                            displayName: "Ajout du projet",
                            args: [newProjectName, newProjectPath, newProjectTarget.backendValue, installNow ? "true" : "false"]
                        )
                    }

                    if let result = center.lastResult, newProjectName == lastActionProject {
                        ResultPanel(result: result)
                    }
                }
                .padding()
                .background(.quaternary.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                Spacer()
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var lastActionProject: String {
        if !projectName.isEmpty {
            return projectName
        }
        return newProjectName
    }

    private func isAbsolutePath(_ path: String) -> Bool {
        path.trimmingCharacters(in: .whitespaces).starts(with: "/")
    }

    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Sélectionnez le dossier du projet"

        if panel.runModal() == .OK, let url = panel.urls.first {
            newProjectPath = url.path
        }
    }
}
