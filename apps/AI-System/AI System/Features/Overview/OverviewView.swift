import SwiftUI

/// Vue d'ensemble — the conclusion first, technical output never (FR-OV-05).
struct OverviewView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(ActivityStore.self) private var activityStore
    @State private var model = OverviewViewModel()

    /// Lets the Overview hand a project over to the Projects destination
    /// (FR-NAV-02).
    var onOpenProject: (String) -> Void = { _ in }

    /// Opens one activity in the Activité destination (FR-NAV-03).
    var onOpenActivity: (UUID) -> Void = { _ in }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.sectionGap) {
                summarySection

                if let message = model.errorMessage {
                    InlineFeedbackView(
                        type: .error,
                        message: message
                    )
                    .padding(.horizontal, Spacing.standard)
                }

                if !model.topActions.isEmpty {
                    actionsSection
                }

                projectsSection

                recentActivitySection
            }
            .padding(.vertical, Spacing.standard)
        }
        .functionalAnimation(model.displayState, reduceMotion: reduceMotion)
        .toolbar { toolbarContent }
        .onReceive(NotificationCenter.default.publisher(for: .refreshRequested)) { _ in
            Task { await model.load() }
        }
        .task {
            if !model.hasAttemptedLoad {
                await model.load()
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button {
                Task { await model.runCheckThenRefresh(recordingIn: activityStore) }
            } label: {
                Label("Vérifier maintenant", systemImage: "checkmark.shield")
            }
            .disabled(model.isBusy)
            .help("Lancer la vérification globale du système")
        }

        ToolbarItem {
            Menu {
                Button("Actualiser l'état") {
                    Task { await model.load() }
                }
                .disabled(model.isBusy)

                Divider()

                Button("Ouvrir le rapport Inventory") {
                    open(action: "open-inventory")
                }
                Button("Ouvrir le rapport Doctor") {
                    open(action: "open-doctor")
                }
            } label: {
                Label("Actions secondaires", systemImage: "ellipsis.circle")
            }
            .help("Autres actions")
        }
    }

    // MARK: - Sections

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: Spacing.related) {
            SystemStateHeader(
                state: model.displayState,
                title: model.stateTitle,
                description: model.stateDescription,
                lastObservation: model.lastObservationText
            )

            HStack(spacing: Spacing.grouped) {
                Button {
                    Task { await model.runCheckThenRefresh(recordingIn: activityStore) }
                } label: {
                    if model.isBusy {
                        HStack(spacing: Spacing.micro) {
                            ProgressView().controlSize(.small)
                            Text("Vérification…")
                        }
                    } else {
                        Text(primaryActionTitle)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(model.isBusy)

                if model.remainingActionCount > 0 || !model.topActions.isEmpty {
                    Button("Examiner les actions") {
                        if let first = model.topActions.first {
                            onOpenProject(first.project)
                        }
                    }
                    .disabled(model.topActions.isEmpty)
                }
            }
        }
        .padding(.horizontal, Spacing.standard)
    }

    private var primaryActionTitle: String {
        switch model.displayState {
        case .unknown: return "Vérifier maintenant"
        case .error: return "Réessayer"
        default: return "Vérifier maintenant"
        }
    }

    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeaderView(
                title: "Actions requises",
                subtitle: model.remainingActionCount > 0
                    ? "\(model.topActions.count) sur \(model.actions.count)"
                    : nil
            )

            VStack(spacing: 0) {
                ForEach(model.topActions) { action in
                    ActionRow(action: action) {
                        onOpenProject(action.project)
                    }
                    if action.id != model.topActions.last?.id {
                        Divider().padding(.leading, Spacing.standard)
                    }
                }
            }
            .background(.quaternary.opacity(0.25), in: RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal, Spacing.standard)

            if model.remainingActionCount > 0 {
                Button("Voir les \(model.remainingActionCount) autres actions") {
                    if let first = model.actions.first {
                        onOpenProject(first.project)
                    }
                }
                .buttonStyle(.link)
                .padding(.horizontal, Spacing.standard)
                .padding(.top, Spacing.related)
            }
        }
    }

    private var projectsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeaderView(title: "Projets", subtitle: nil)

            if let summary = model.summary {
                HStack(spacing: Spacing.sectionGap) {
                    CountItem(label: "Actifs", value: "\(summary.projectsTotal)", state: nil)
                    CountItem(label: "Sains", value: "\(summary.projectsHealthy)", state: .healthy)
                    CountItem(label: "Attention", value: "\(summary.projectsAttention)", state: .attention)
                    CountItem(label: "Erreur", value: "\(summary.projectsError)", state: .error)
                    Spacer()
                }
                .padding(.horizontal, Spacing.standard)
            } else {
                Text("Non vérifié")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, Spacing.standard)
            }

            if !model.projectsNeedingAttention.isEmpty {
                VStack(spacing: 0) {
                    ForEach(model.projectsNeedingAttention) { project in
                        ProjectRow(project: project) {
                            onOpenProject(project.name)
                        }
                        if project.id != model.projectsNeedingAttention.last?.id {
                            Divider().padding(.leading, Spacing.standard)
                        }
                    }
                }
                .background(.quaternary.opacity(0.25), in: RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal, Spacing.standard)
                .padding(.top, Spacing.related)
            }
        }
    }

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeaderView(title: "Activité récente", subtitle: nil)

            let recent = activityStore.recent(4)
            if recent.isEmpty {
                Text("Aucune opération lancée pendant cette session.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, Spacing.standard)
            } else {
                VStack(spacing: 0) {
                    ForEach(recent) { activity in
                        RecentActivityRow(activity: activity) {
                            onOpenActivity(activity.id)
                        }
                        if activity.id != recent.last?.id {
                            Divider().padding(.leading, Spacing.standard)
                        }
                    }
                }
                .background(.quaternary.opacity(0.25), in: RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal, Spacing.standard)
            }
        }
    }

    // MARK: - Helpers

    private func open(action: String) {
        Task { await ProjectSkillsService().openResource(action) }
    }
}

// MARK: - Header

private struct SystemStateHeader: View {
    let state: SystemState
    let title: String
    let description: String
    let lastObservation: String?

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.grouped) {
            Image(systemName: state.symbolName)
                .font(.system(size: 28))
                .foregroundStyle(state.tint)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Spacing.micro) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(lastObservation.map { "Dernière observation : \($0)" }
                    ?? "Aucune observation datée")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, Spacing.micro)
            }

            Spacer(minLength: 0)
        }
        // The status is announced as text, never carried by colour alone.
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(description)")
    }
}

// MARK: - Rows

private struct ActionRow: View {
    let action: OverviewAction
    let open: () -> Void

    var body: some View {
        HStack(spacing: Spacing.grouped) {
            Image(systemName: action.severity.symbolName)
                .foregroundStyle(action.severity == .error ? .red : .orange)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(action.project) · \(action.skill)")
                    .font(.body)
                Text(action.status.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: Spacing.grouped)

            Button("Ouvrir", action: open)
                .buttonStyle(.bordered)
                .controlSize(.small)
        }
        .padding(.horizontal, Spacing.standard)
        .padding(.vertical, Spacing.grouped)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(action.skill) dans \(action.project). \(action.status.displayName). \(action.severity.displayName)."
        )
    }
}

private struct ProjectRow: View {
    let project: OverviewProject
    let open: () -> Void

    var body: some View {
        HStack(spacing: Spacing.grouped) {
            Image(systemName: project.state.symbolName)
                .foregroundStyle(project.state.tint)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(project.name)
                    .font(.body)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: Spacing.grouped)

            Button("Ouvrir", action: open)
                .buttonStyle(.bordered)
                .controlSize(.small)
        }
        .padding(.horizontal, Spacing.standard)
        .padding(.vertical, Spacing.grouped)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(project.name). \(project.state.displayName). \(subtitle)")
    }

    private var subtitle: String {
        if let error = project.error {
            return error.message
        }
        let count = project.summary.actionRequired
        return count == 1 ? "1 action requise" : "\(count) actions requises"
    }
}

private struct CountItem: View {
    let label: String
    let value: String
    let state: ProjectState?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(state?.tint ?? .primary)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label) : \(value)")
    }
}

private struct SectionHeaderView: View {
    let title: String
    let subtitle: String?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.headline)
            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, Spacing.standard)
        .padding(.bottom, Spacing.related)
    }
}

// MARK: - Recent activity row

private struct RecentActivityRow: View {
    let activity: Activity
    let open: () -> Void

    var body: some View {
        HStack(spacing: Spacing.grouped) {
            Image(systemName: activity.status.symbolName)
                .foregroundStyle(activity.status.tint)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(activity.displayName)
                    .font(.body)
                Text(activity.targetDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: Spacing.grouped)

            if let duration = activity.durationDescription {
                Text(duration)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(activity.startedAt, style: .relative)
                .font(.caption)
                .foregroundStyle(.secondary)

            Button("Voir", action: open)
                .buttonStyle(.bordered)
                .controlSize(.small)
        }
        .padding(.horizontal, Spacing.standard)
        .padding(.vertical, Spacing.grouped)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(activity.displayName). \(activity.targetDescription). \(activity.status.displayName)."
        )
    }
}
