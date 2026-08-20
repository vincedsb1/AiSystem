import AppKit
import SwiftUI

/// Projets — select a project, understand its state, inspect its skills.
/// Read-only for UX-04: mutations arrive with UX-05.
struct ProjectsView: View {
    @State private var model = ProjectsViewModel()
    @AppStorage("selectedProjectName") private var savedProjectName = ""

    /// Project handed over by the Overview (FR-NAV-02).
    @Binding var pendingSelection: String?

    @State private var isAddingProject = false

    var body: some View {
        HSplitView {
            projectList
                .frame(minWidth: 220, idealWidth: 260, maxWidth: 340)

            detail
                .frame(minWidth: 420, maxWidth: .infinity)
        }
        .toolbar { toolbarContent }
        .task {
            if !model.hasAttemptedLoad {
                await model.loadProjects()
                restoreSelection()
                await model.scanSelectedProject()
            }
        }
        .onChange(of: pendingSelection) { _, name in
            guard let name else { return }
            model.select(projectNamed: name, focusActions: true)
            pendingSelection = nil
            Task { await model.scanSelectedProject() }
        }
        .sheet(isPresented: $isAddingProject) {
            AddProjectSheet(
                onCancel: { isAddingProject = false },
                onAdded: { name in
                    isAddingProject = false
                    Task {
                        await model.loadProjects()
                        model.select(projectNamed: name, focusActions: false)
                        await model.scanSelectedProject()
                    }
                }
            )
        }
        .sheet(item: $model.importCandidate) { skill in
            ImportSkillSheet(
                skill: skill,
                projectName: model.selectedProjectName ?? "",
                source: model.importSource(for: skill) ?? .codex,
                sharedTargets: model.sharedTargets,
                isRunning: model.operationState(for: skill).isRunning,
                onCancel: { model.importCandidate = nil },
                onConfirm: { source in
                    Task { await model.importSkill(skill, source: source) }
                }
            )
        }
        .onChange(of: model.selectedProjectName) { _, name in
            savedProjectName = name ?? ""
            guard name != nil else { return }
            Task { await model.scanSelectedProject() }
        }
    }

    /// FR-PROJ-02: the last selection is restored at launch when it still exists.
    private func restoreSelection() {
        guard model.selectedProjectName == nil,
              !savedProjectName.isEmpty,
              model.projects.contains(where: { $0.name == savedProjectName })
        else { return }
        model.selectedProjectName = savedProjectName
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button {
                isAddingProject = true
            } label: {
                Label("Ajouter un projet", systemImage: "plus")
            }
            .help("Ajouter un projet (⌘N)")
            .keyboardShortcut("n", modifiers: .command)
        }

        ToolbarItem(placement: .primaryAction) {
            Button {
                Task { await model.refreshAll() }
            } label: {
                Label("Actualiser", systemImage: "arrow.clockwise")
            }
            .disabled(model.isBusy)
            .help("Recharger la liste et analyser le projet sélectionné")
        }
    }

    // MARK: - Project list

    private var projectList: some View {
        VStack(spacing: 0) {
            if let message = model.projectsError {
                InlineFeedbackView(type: .error, message: message)
                    .padding(Spacing.related)
            }

            if model.isLoadingProjects && model.projects.isEmpty {
                LoadingStateView(message: "Chargement des projets…")
            } else if model.isEmpty {
                // FR-PROJ-04
                EmptyStateView(
                    symbolName: "folder.badge.questionmark",
                    title: "Aucun projet actif",
                    description: "Ajoutez un projet pour commencer à gérer ses skills.",
                    actionLabel: "Ajouter un projet",
                    action: { isAddingProject = true }
                )
            } else {
                List(model.sortedProjects, selection: $model.selectedProjectName) { project in
                    ProjectListRow(project: project)
                        .tag(project.name)
                }
                .listStyle(.sidebar)
            }
        }
    }

    // MARK: - Detail

    @ViewBuilder
    private var detail: some View {
        if model.selectedProject == nil {
            // FR-PROJ-03
            EmptyStateView(
                symbolName: "sidebar.left",
                title: "Aucun projet sélectionné",
                description: "Sélectionnez un projet pour consulter ses skills."
            )
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.sectionGap) {
                    header

                    if let summary = model.lastActionSummary {
                        InlineFeedbackView(
                            type: model.lastActionSucceeded ? .success : .error,
                            message: summary,
                            actionLabel: "Masquer",
                            action: { model.dismissActionSummary() }
                        )
                        .padding(.horizontal, Spacing.standard)
                    }

                    if let message = model.scanError {
                        InlineFeedbackView(
                            type: .error,
                            message: message,
                            actionLabel: "Réessayer",
                            action: { Task { await model.scanSelectedProject() } }
                        )
                        .padding(.horizontal, Spacing.standard)
                    }

                    summarySection
                    skillsSection
                }
                .padding(.vertical, Spacing.standard)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.related) {
            HStack(alignment: .top, spacing: Spacing.grouped) {
                Image(systemName: model.detailState.symbolName)
                    .font(.system(size: 24))
                    .foregroundStyle(model.detailState.tint)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: Spacing.micro) {
                    Text(model.selectedProject?.name ?? "")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text(headerSubtitle)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(model.lastScanText.map { "Dernière analyse : \($0)" }
                        ?? "Pas encore analysé")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(
                "\(model.selectedProject?.name ?? ""). \(model.detailState.displayName). \(headerSubtitle)"
            )

            HStack(spacing: Spacing.grouped) {
                Button {
                    Task { await model.scanSelectedProject() }
                } label: {
                    if model.isScanning {
                        HStack(spacing: Spacing.micro) {
                            ProgressView().controlSize(.small)
                            Text("Analyse…")
                        }
                    } else {
                        Text(model.primaryActionTitle)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(model.isScanning)

                if model.canSyncProject() {
                    Button {
                        Task { await model.syncSelectedProject() }
                    } label: {
                        if model.isSyncing {
                            HStack(spacing: Spacing.micro) {
                                ProgressView().controlSize(.small)
                                Text("Synchronisation…")
                            }
                        } else {
                            Text("Synchroniser")
                        }
                    }
                    .disabled(model.isMutating)
                }

                secondaryMenu
            }
        }
        .padding(.horizontal, Spacing.standard)
    }

    private var headerSubtitle: String {
        guard let summary = model.summary else {
            return model.isScanning ? "Analyse en cours…" : "Skills non vérifiés"
        }
        let managed = "\(summary.managed) \(summary.managed <= 1 ? "skill géré" : "skills gérés")"
        if summary.actionRequired == 0 {
            return "\(managed) sur \(summary.total) — aucune action requise"
        }
        let actions = summary.actionRequired == 1
            ? "1 action requise"
            : "\(summary.actionRequired) actions requises"
        return "\(managed) sur \(summary.total) — \(actions)"
    }

    private var secondaryMenu: some View {
        Menu {
            Button("Ouvrir dans Finder") { openInFinder() }
            Button("Ouvrir dans Terminal") { openInTerminal() }
            Button("Copier le chemin") { copyPath() }
        } label: {
            Label("Actions secondaires", systemImage: "ellipsis.circle")
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
        .disabled(model.selectedProject?.root == nil)
        .help("Autres actions sur ce projet")
    }

    // MARK: - Summary

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: "Résumé")

            if let summary = model.summary {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 132), spacing: Spacing.standard)],
                    alignment: .leading,
                    spacing: Spacing.grouped
                ) {
                    SummaryItem(label: "Partagés", value: "\(summary.shared)")
                    SummaryItem(label: "Spécifiques", value: "\(summary.projectSpecific)")
                    SummaryItem(label: "Synchronisés", value: "\(summary.managed)")
                    SummaryItem(
                        label: "Actions requises",
                        value: "\(summary.actionRequired)",
                        tint: summary.actionRequired > 0 ? .orange : nil
                    )
                    SummaryItem(label: "Exceptions attendues", value: "\(summary.expectedExceptions)")
                    SummaryItem(
                        label: "Conflits",
                        value: "\(summary.conflicts)",
                        tint: summary.conflicts > 0 ? .red : nil
                    )
                }
                .padding(.horizontal, Spacing.standard)
            } else {
                // Spec 10.6: an unavailable value reads as unverified, never as
                // a confirmed zero.
                Text("Non vérifié")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, Spacing.standard)
            }
        }
    }

    // MARK: - Skills

    private var skillsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(
                title: "Skills",
                subtitle: model.scan == nil
                    ? nil
                    : "\(model.visibleSkills.count) résultat\(model.visibleSkills.count <= 1 ? "" : "s")"
            )

            if model.scan != nil {
                filterBar
                    .padding(.horizontal, Spacing.standard)
                    .padding(.bottom, Spacing.grouped)
            }

            if model.isScanning && model.scan == nil {
                LoadingStateView(message: "Analyse du projet…")
                    .frame(minHeight: 160)
            } else if model.scan == nil {
                EmptyStateView(
                    symbolName: "questionmark.folder",
                    title: "Projet non analysé",
                    description: "Lancez une analyse pour afficher les skills de ce projet.",
                    actionLabel: "Analyser",
                    action: { Task { await model.scanSelectedProject() } }
                )
                .frame(minHeight: 200)
            } else if model.visibleSkills.isEmpty {
                EmptyStateView(
                    symbolName: "line.3.horizontal.decrease.circle",
                    title: "Aucun résultat",
                    description: model.hasActiveFilter
                        ? "Aucun skill ne correspond au filtre actuel."
                        : "Ce projet ne déclare aucun skill.",
                    actionLabel: model.hasActiveFilter ? "Effacer le filtre" : nil,
                    action: model.hasActiveFilter ? { model.clearFilters() } : nil
                )
                .frame(minHeight: 200)
            } else {
                skillsTable
            }
        }
    }

    private var filterBar: some View {
        HStack(spacing: Spacing.grouped) {
            Picker("Filtre", selection: $model.filter) {
                ForEach(SkillFilter.allCases) { option in
                    Text("\(option.displayName) (\(model.count(for: option)))")
                        .tag(option)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .fixedSize()

            TextField("Rechercher un skill", text: $model.searchText)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 260)
                .accessibilityLabel("Rechercher un skill par nom ou identifiant canonical")
        }
    }

    private var skillsTable: some View {
        VStack(spacing: 0) {
            ForEach(model.visibleSkills) { skill in
                SkillRowView(
                    skill: skill,
                    sharedTargets: model.sharedTargets,
                    operation: model.operationState(for: skill),
                    canImport: model.canImport(skill),
                    onImport: { model.importCandidate = skill }
                )
                if skill.id != model.visibleSkills.last?.id {
                    Divider().padding(.leading, Spacing.standard)
                }
            }
        }
        .background(.quaternary.opacity(0.25), in: RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal, Spacing.standard)
    }

    // MARK: - Secondary actions
    // Opening a folder is a presentation concern, so it stays in SwiftUI. The
    // path always comes from the backend, never from user input.

    private func openInFinder() {
        guard let root = model.selectedProject?.root else { return }
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: root)
    }

    private func openInTerminal() {
        guard let root = model.selectedProject?.root,
              let terminal = NSWorkspace.shared.urlForApplication(
                withBundleIdentifier: "com.apple.Terminal"
              )
        else { return }
        NSWorkspace.shared.open(
            [URL(fileURLWithPath: root)],
            withApplicationAt: terminal,
            configuration: NSWorkspace.OpenConfiguration()
        )
    }

    private func copyPath() {
        guard let root = model.selectedProject?.root else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(root, forType: .string)
    }
}

// MARK: - Rows

private struct ProjectListRow: View {
    let project: OverviewProject

    var body: some View {
        HStack(spacing: Spacing.related) {
            Image(systemName: project.state.symbolName)
                .foregroundStyle(project.state.tint)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 1) {
                Text(project.name)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: Spacing.micro)

            if project.summary.actionRequired > 0 {
                Text("\(project.summary.actionRequired)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(project.state.tint.opacity(0.18), in: Capsule())
                    .foregroundStyle(project.state.tint)
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(project.name). \(project.state.displayName). \(subtitle)")
    }

    private var subtitle: String {
        if project.error != nil { return "Analyse impossible" }
        let count = project.summary.actionRequired
        if count == 0 { return project.state.displayName }
        return count == 1 ? "1 action requise" : "\(count) actions requises"
    }
}

private struct SkillRowView: View {
    let skill: SkillRow
    let sharedTargets: [String]
    let operation: SkillOperationState
    let canImport: Bool
    let onImport: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: Spacing.grouped) {
            Image(systemName: skill.status.symbolName)
                .foregroundStyle(skill.status.tint)
                .frame(width: 18)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(skill.name)
                    .font(.body)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Text(skill.status.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(minWidth: 160, alignment: .leading)

            Spacer(minLength: Spacing.related)

            Text(scopeLabel)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 84, alignment: .leading)

            PresenceBadge(label: "Claude", state: presence(for: "claude"))
            PresenceBadge(label: "Codex", state: presence(for: "codex"))

            action
                .frame(width: 96, alignment: .trailing)
        }
        .padding(.horizontal, Spacing.standard)
        .padding(.vertical, Spacing.grouped)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    /// Only the row running an operation shows progress (spec 22.3).
    @ViewBuilder
    private var action: some View {
        switch operation {
        case .running:
            ProgressView().controlSize(.small)
        case .succeeded:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .help("Import terminé")
        case .failed(let message):
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
                .help(message)
        case .idle:
            // The action is offered only when the backend declared it allowed
            // (spec 11.2).
            if canImport {
                Button("Importer", action: onImport)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
        }
    }

    private var scopeLabel: String {
        switch skill.scope {
        case "shared": return "Partagé"
        case "project": return "Spécifique"
        default: return "—"
        }
    }

    /// A platform the project does not target is "non concerné", not "absent".
    private func presence(for target: String) -> PresenceBadge.State {
        if skill.scope == "shared" && !sharedTargets.contains(target) {
            return .notTargeted
        }
        let present = target == "claude" ? skill.presence.claude : skill.presence.codex
        return present ? .present : .absent
    }

    private var accessibilityDescription: String {
        var parts = [skill.name, scopeLabel, skill.status.displayName]
        parts.append("Claude : \(presence(for: "claude").accessibilityLabel)")
        parts.append("Codex : \(presence(for: "codex").accessibilityLabel)")
        if let exception = skill.exception, let reason = exception.reason {
            parts.append("Exception attendue : \(reason)")
        }
        return parts.joined(separator: ". ")
    }
}

private struct PresenceBadge: View {
    enum State {
        case present
        case absent
        case notTargeted

        var symbolName: String {
            switch self {
            case .present: return "checkmark.circle.fill"
            case .absent: return "circle.dashed"
            case .notTargeted: return "minus.circle"
            }
        }

        var tint: Color {
            switch self {
            case .present: return .green
            case .absent: return .secondary
            case .notTargeted: return .secondary
            }
        }

        var accessibilityLabel: String {
            switch self {
            case .present: return "présent"
            case .absent: return "absent"
            case .notTargeted: return "non concerné"
            }
        }
    }

    let label: String
    let state: State

    var body: some View {
        VStack(spacing: 1) {
            Image(systemName: state.symbolName)
                .foregroundStyle(state.tint)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(width: 56)
        .help("\(label) : \(state.accessibilityLabel)")
    }
}

private struct SummaryItem: View {
    let label: String
    let value: String
    var tint: Color?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(tint ?? .primary)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label) : \(value)")
    }
}
