import AppKit
import SwiftUI

/// Projets — select a project, understand its state, inspect its skills.
struct ProjectsView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(ActivityStore.self) private var activityStore
    @State private var model = ProjectsViewModel()
    @AppStorage("selectedProjectName") private var savedProjectName = ""

    /// Project handed over by the Overview.
    @Binding var pendingSelection: String?

    @State private var isAddingProject = false
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        HSplitView {
            projectList
                .frame(minWidth: 200, idealWidth: 260, maxWidth: 280)

            detail
                .frame(minWidth: 420, maxWidth: .infinity)
        }
        .functionalAnimation(model.selectedProjectName, reduceMotion: reduceMotion)
        .toolbar { toolbarContent }
        .task {
            if !model.hasAttemptedLoad {
                await model.loadProjects()
                restoreSelection()
                await model.scanSelectedProject()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .addProjectRequested)) { _ in
            isAddingProject = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .refreshRequested)) { _ in
            Task { await model.refreshAll() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .searchRequested)) { _ in
            isSearchFocused = true
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
                    Task {
                        await model.importSkill(skill, source: source, recordingIn: activityStore)
                    }
                }
            )
        }
        .onChange(of: model.selectedProjectName) { _, name in
            savedProjectName = name ?? ""
            guard name != nil else { return }
            Task { await model.scanSelectedProject() }
        }
    }

    /// FR-PROJ-02: restore the last project when it still exists.
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
    }

    // MARK: - Project list

    private var projectList: some View {
        VStack(spacing: 0) {
            if let message = model.projectsError {
                InlineFeedbackView(type: .error, message: message)
                    .padding(Spacing.sm)
            }

            if model.isLoadingProjects && model.projects.isEmpty {
                LoadingStateView(message: "Chargement des projets…")
            } else if model.isEmpty {
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
            EmptyStateView(
                symbolName: "sidebar.left",
                title: "Aucun projet sélectionné",
                description: "Sélectionnez un projet pour consulter ses skills."
            )
        } else {
            ScrollView {
                AdaptiveContentContainer {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        header

                        if let summary = model.lastActionSummary {
                            InlineFeedbackView(
                                type: model.lastActionSucceeded ? .success : .error,
                                message: summary,
                                actionLabel: "Masquer",
                                action: { model.dismissActionSummary() }
                            )
                        }

                        if let message = model.scanError {
                            InlineFeedbackView(
                                type: .error,
                                message: message,
                                actionLabel: "Réessayer",
                                action: { Task { await model.scanSelectedProject() } }
                            )
                        }

                        summarySection
                        skillsSection
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var header: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: Spacing.lg) {
                headerInfo
                Spacer(minLength: Spacing.lg)
                headerActions
            }
            .frame(minWidth: 640, alignment: .leading)

            VStack(alignment: .leading, spacing: Spacing.md) {
                headerInfo
                headerActions
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var headerInfo: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: model.detailState.symbolName)
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(model.detailState.tint)
                .frame(width: 32, height: 32)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(model.selectedProject?.name ?? "")
                    .font(.system(size: 22, weight: .semibold))

                Text(model.headerSummaryText)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(model.lastScanText.map { "Vérifié \($0)" } ?? "Pas encore vérifié")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityLabel(headerAccessibilityLabel)
    }

    private var headerAccessibilityLabel: String {
        let name = model.selectedProject?.name ?? ""
        return name + ". " + model.detailState.displayName + ". " + model.headerSummaryText
    }

    @ViewBuilder
    private var headerActions: some View {
        HStack(spacing: Spacing.sm) {
            Button {
                Task { await model.scanSelectedProject() }
            } label: {
                if model.isScanning {
                    HStack(spacing: Spacing.xxs) {
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
                    Task { await model.syncSelectedProject(recordingIn: activityStore) }
                } label: {
                    if model.isSyncing {
                        HStack(spacing: Spacing.xxs) {
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

    private var secondaryMenu: some View {
        Menu {
            Button("Ouvrir dans Finder") { openInFinder() }
            Button("Ouvrir dans Terminal") { openInTerminal() }
            Button("Copier le chemin") { copyPath() }
        } label: {
            Label("Plus d’actions", systemImage: "ellipsis.circle")
                .labelStyle(.iconOnly)
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
        .disabled(model.selectedProject?.root == nil)
        .help("Plus d’actions pour \(model.selectedProject?.name ?? "ce projet")")
        .accessibilityLabel("Plus d’actions pour \(model.selectedProject?.name ?? "ce projet")")
    }

    // MARK: - Summary

    private var summarySection: some View {
        SectionSurface(title: "Résumé") {
            if let summary = model.summary {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: Spacing.lg) {
                        summaryMetrics(summary)
                    }
                    .frame(minWidth: 640, alignment: .leading)

                    LazyVGrid(
                        columns: [GridItem(.flexible()), GridItem(.flexible())],
                        alignment: .leading,
                        spacing: Spacing.md
                    ) {
                        summaryMetrics(summary)
                    }
                }

                if let composition = model.compositionText {
                    Text(composition)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.top, Spacing.xxs)
                }

                if summary.conflicts > 0 {
                    Label(
                        "\(summary.conflicts) conflit\(summary.conflicts == 1 ? "" : "s") à examiner",
                        systemImage: "exclamationmark.triangle"
                    )
                    .font(.subheadline)
                    .foregroundStyle(.orange)
                    .padding(.top, Spacing.xxs)
                }
            } else {
                Text("Non vérifié")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func summaryMetrics(_ summary: SkillSummary) -> some View {
        MetricItemView(
            label: "Total",
            value: "\(summary.total)",
            symbolName: "square.grid.2x2",
            tint: nil
        )
        MetricItemView(
            label: "Synchronisés",
            value: "\(summary.managed)",
            symbolName: "checkmark.circle",
            tint: summary.managed > 0 ? .green : nil
        )
        MetricItemView(
            label: "Exceptions",
            value: "\(summary.expectedExceptions)",
            symbolName: "info.circle",
            tint: nil
        )
        MetricItemView(
            label: "À examiner",
            value: "\(summary.actionRequired)",
            symbolName: "exclamationmark.triangle",
            tint: summary.actionRequired > 0 ? .orange : nil
        )
    }

    // MARK: - Skills

    private var skillsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(alignment: .firstTextBaseline) {
                Text("Skills")
                    .font(.title3.weight(.semibold))
                if model.scan != nil {
                    Text("\(model.visibleSkills.count) résultat\(model.visibleSkills.count == 1 ? "" : "s")")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            if model.scan != nil {
                filterBar
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
                    title: model.emptyStateTitle,
                    description: model.emptyStateDescription,
                    actionLabel: model.emptyStateActionTitle,
                    action: model.emptyStateActionTitle == nil ? nil : { model.clearEmptyState() }
                )
                .frame(minHeight: 200)
            } else {
                skillsTable
            }
        }
    }

    private var filterBar: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: Spacing.sm) {
                segmentedFilterPicker
                    .frame(maxWidth: .infinity)

                searchField
                    .frame(width: 250)
            }
            .frame(minWidth: 620)

            VStack(alignment: .leading, spacing: Spacing.sm) {
                menuFilterPicker
                searchField
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var segmentedFilterPicker: some View {
        Picker("Filtrer les skills", selection: $model.filter) {
            ForEach(SkillFilter.allCases) { option in
                Text("\(option.displayName) (\(model.count(for: option)))")
                    .tag(option)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .accessibilityLabel("Filtrer les skills")
    }

    private var menuFilterPicker: some View {
        Picker("Filtrer les skills", selection: $model.filter) {
            ForEach(SkillFilter.allCases) { option in
                Text("\(option.displayName) (\(model.count(for: option)))")
                    .tag(option)
            }
        }
        .pickerStyle(.menu)
        .accessibilityLabel("Filtrer les skills")
    }

    private var searchField: some View {
        TextField("Rechercher un skill", text: $model.searchText)
            .textFieldStyle(.roundedBorder)
            .focused($isSearchFocused)
            .accessibilityLabel("Rechercher un skill par nom ou identifiant canonical")
    }

    private var skillsTable: some View {
        ViewThatFits(in: .horizontal) {
            skillsTableSurface

            ScrollView(.horizontal, showsIndicators: true) {
                skillsTableSurface
                    .frame(minWidth: 520, alignment: .leading)
            }
        }
    }

    private var skillsTableSurface: some View {
        SemanticSurface {
            VStack(spacing: 0) {
                SkillTableHeader()
                Divider()

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
        }
    }

    // MARK: - Secondary actions

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

// MARK: - Project list row

private struct ProjectListRow: View {
    let project: OverviewProject

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: project.state.symbolName)
                .font(.caption)
                .foregroundStyle(project.state.tint)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(project.name)
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                    .truncationMode(.middle)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: Spacing.xxs)
        }
        .frame(minHeight: 48, alignment: .leading)
        .padding(.horizontal, Spacing.xs)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(project.name). \(subtitle)")
    }

    private var subtitle: String {
        if project.error != nil { return "Analyse impossible" }

        switch project.state {
        case .healthy:
            return "À jour"
        case .attention, .error:
            let count = project.summary.actionRequired
            return count == 1 ? "1 élément à examiner" : "\(count) éléments à examiner"
        case .unknown:
            return "Non vérifié"
        case .disabled:
            return "Désactivé"
        }
    }
}

// MARK: - Skills table

private enum SkillTableLayout {
    static var columns: [GridItem] {
        [
            GridItem(.flexible(minimum: 80), alignment: .leading),
            GridItem(.fixed(60), alignment: .leading),
            GridItem(.fixed(40), alignment: .center),
            GridItem(.fixed(40), alignment: .center),
            GridItem(.fixed(64), alignment: .trailing)
        ]
    }
}

private struct SkillTableHeader: View {
    var body: some View {
        LazyVGrid(
            columns: SkillTableLayout.columns,
            alignment: .leading,
            spacing: 0
        ) {
            Text("Skill")
            Text("Type")
            Text("Claude").frame(maxWidth: .infinity)
            Text("Codex").frame(maxWidth: .infinity)
            Text("État").frame(maxWidth: .infinity, alignment: .trailing)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .frame(maxWidth: .infinity)
        .accessibilityHidden(true)
    }
}

private struct SkillRowView: View {
    let skill: SkillRow
    let sharedTargets: [String]
    let operation: SkillOperationState
    let canImport: Bool
    let onImport: () -> Void

    var body: some View {
        LazyVGrid(
            columns: SkillTableLayout.columns,
            alignment: .leading,
            spacing: 0
        ) {
            HStack(alignment: .center, spacing: Spacing.sm) {
                Image(systemName: statusSymbol)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(statusTint)
                    .frame(width: 18)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(skill.name)
                        .font(.body)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Text(skill.status.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Text(scopeLabel)
                .font(.caption)
                .foregroundStyle(.secondary)

            PresenceBadge(label: "Claude", state: presence(for: "claude"))
            PresenceBadge(label: "Codex", state: presence(for: "codex"))

            action
                .frame(width: 64, alignment: .trailing)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    private var statusSymbol: String {
        skill.status.requiresAction ? skill.status.symbolName : "checkmark"
    }

    private var statusTint: Color {
        skill.status.requiresAction ? skill.status.tint : .secondary
    }

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

    /// A platform the project does not target is "non requis", not absent.
    private func presence(for target: String) -> PresenceBadge.State {
        if skill.status == .expectedClaudeOnly, target == "codex" {
            return .notRequired
        }
        if skill.status == .expectedCodexOnly, target == "claude" {
            return .notRequired
        }
        if skill.scope == "shared" && !sharedTargets.contains(target) {
            return .notRequired
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
        case notRequired

        var symbolName: String {
            switch self {
            case .present: return "checkmark"
            case .absent: return "circle.dashed"
            case .notRequired: return "minus"
            }
        }

        var tint: Color {
            switch self {
            case .present: return .green
            case .absent, .notRequired: return .secondary
            }
        }

        var accessibilityLabel: String {
            switch self {
            case .present: return "présent"
            case .absent: return "absent"
            case .notRequired: return "non requis"
            }
        }

        var shortLabel: String {
            switch self {
            case .present: return "Présent"
            case .absent: return "Absent"
            case .notRequired: return "Non requis"
            }
        }
    }

    let label: String
    let state: State

    var body: some View {
        VStack(spacing: 1) {
            Image(systemName: state.symbolName)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(state.tint)
            Text(state.shortLabel)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(width: 40)
        .help("\(label) : \(state.accessibilityLabel)")
    }
}

#Preview {
    ContentView()
}
