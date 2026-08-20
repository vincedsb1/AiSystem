import SwiftUI

/// Vue d'ensemble — a clear conclusion first, with technical detail kept in
/// the Activity destination.
struct OverviewView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(ActivityStore.self) private var activityStore
    @State private var model = OverviewViewModel()

    /// Lets the Overview hand a project over to the Projects destination.
    var onOpenProject: (String) -> Void = { _ in }

    /// Opens one activity in the Activité destination.
    var onOpenActivity: (UUID) -> Void = { _ in }

    var body: some View {
        ScrollView {
            AdaptiveContentContainer {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    hero

                    if let message = model.errorMessage, model.overview != nil {
                        InlineFeedbackView(type: .error, message: message)
                    }

                    if let summary = model.summary {
                        ProjectHealthSummaryView(
                            summary: summary,
                            onOpenAttention: openFirstActionProject
                        )
                    }

                    if !model.topActions.isEmpty {
                        requiredActions
                    }

                    recentActivity
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
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

    // MARK: - Hero

    private var hero: some View {
        HealthHeroView(
            state: model.displayState,
            title: model.stateTitle,
            description: model.stateDescription,
            lastObservation: model.lastObservationText,
            actionTitle: heroActionTitle,
            isBusy: model.isBusy,
            onPrimaryAction: heroPrimaryAction,
            secondaryActionTitle: model.displayState == .error
                && activityStore.recent(1).first != nil
                ? "Afficher l’activité"
                : nil,
            onSecondaryAction: openLatestActivity
        )
    }

    private var heroActionTitle: String? {
        switch model.displayState {
        case .checking:
            return nil
        case .healthy:
            return "Vérifier à nouveau"
        case .attention:
            return model.topActions.isEmpty ? "Vérifier maintenant" : "Examiner les actions"
        case .error:
            return "Réessayer"
        case .unknown:
            return "Vérifier maintenant"
        }
    }

    private func heroPrimaryAction() {
        if model.displayState == .attention, !model.topActions.isEmpty {
            openFirstActionProject()
        } else {
            Task { await model.runCheckThenRefresh(recordingIn: activityStore) }
        }
    }

    private func openFirstActionProject() {
        guard let first = model.topActions.first else { return }
        onOpenProject(first.project)
    }

    private func openLatestActivity() {
        guard let latest = activityStore.recent(1).first else { return }
        onOpenActivity(latest.id)
    }

    // MARK: - Sections

    private var requiredActions: some View {
        SectionSurface(
            title: "Actions requises",
            subtitle: "Les éléments qui demandent votre attention",
            tone: .attention
        ) {
            VStack(spacing: 0) {
                ForEach(Array(model.topActions.prefix(3))) { action in
                    RequiredActionRow(action: action) {
                        onOpenProject(action.project)
                    }

                    if action.id != model.topActions.prefix(3).last?.id {
                        Divider()
                    }
                }
            }
        }
    }

    private var recentActivity: some View {
        SectionSurface(
            title: "Activité récente",
            subtitle: "Les dernières opérations de cette session"
        ) {
            let recent = activityStore.recent(3)
            if recent.isEmpty {
                Text("Les vérifications et synchronisations apparaîtront ici.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, Spacing.xs)
            } else {
                VStack(spacing: 0) {
                    ForEach(recent) { activity in
                        RecentActivityRow(activity: activity) {
                            onOpenActivity(activity.id)
                        }

                        if activity.id != recent.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem {
            Menu {
                Button("Ouvrir Inventory") {
                    open(action: "open-inventory")
                }
                Button("Ouvrir Doctor") {
                    open(action: "open-doctor")
                }
            } label: {
                Label("Actions secondaires", systemImage: "ellipsis.circle")
                    .labelStyle(.iconOnly)
            }
            .help("Rapports et actions secondaires")
            .accessibilityLabel("Rapports et actions secondaires")
        }
    }

    private func open(action: String) {
        Task { await ProjectSkillsService().openResource(action) }
    }
}

// MARK: - Health hero

struct HealthHeroView: View {
    let state: SystemState
    let title: String
    let description: String
    let lastObservation: String?
    let actionTitle: String?
    let isBusy: Bool
    let onPrimaryAction: () -> Void
    let secondaryActionTitle: String?
    let onSecondaryAction: () -> Void

    var body: some View {
        SemanticSurface(tone: state.surfaceTone, cornerRadius: AppRadius.hero) {
            ViewThatFits(in: .horizontal) {
                horizontalContent
                verticalContent
            }
            .padding(Spacing.lg)
        }
        .accessibilityElement(children: .contain)
    }

    private var horizontalContent: some View {
        HStack(alignment: .top, spacing: Spacing.lg) {
            heroText
            Spacer(minLength: Spacing.lg)
            actionControls
        }
        .frame(minWidth: 640, alignment: .leading)
    }

    private var verticalContent: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            heroText
            actionControls
        }
    }

    private var heroText: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            statusIcon

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title)
                    .font(.system(size: 28, weight: .semibold))
                    .fixedSize(horizontal: false, vertical: true)

                Text(description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if let observation = lastObservation {
                    Text("Vérifié " + observation.lowercased())
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else if state == .checking {
                    Text("Votre dernière observation reste visible pendant l’actualisation.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            [title, description, lastObservation.map { "Vérifié \($0)" }]
                .compactMap { $0 }
                .joined(separator: ". ")
        )
    }

    private var statusIcon: some View {
        ZStack {
            Circle()
                .fill(state.tint.opacity(0.14))

            if isBusy {
                ProgressView()
                    .controlSize(.small)
                    .tint(state.tint)
            } else {
                Image(systemName: state.symbolName)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(state.tint)
            }
        }
        .frame(width: 52, height: 52)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var actionControls: some View {
        if let actionTitle {
            VStack(alignment: .trailing, spacing: Spacing.xs) {
                if state == .healthy {
                    Button(actionTitle, action: onPrimaryAction)
                        .buttonStyle(.bordered)
                        .disabled(isBusy)
                } else {
                    Button(actionTitle, action: onPrimaryAction)
                        .buttonStyle(.borderedProminent)
                        .disabled(isBusy)
                }

                if let secondaryActionTitle {
                    Button(secondaryActionTitle, action: onSecondaryAction)
                        .buttonStyle(.link)
                        .disabled(isBusy)
                }
            }
            .fixedSize(horizontal: true, vertical: false)
        } else {
            ProgressView("Vérification en cours…")
                .controlSize(.small)
                .fixedSize(horizontal: true, vertical: false)
        }
    }
}

// MARK: - Project health summary

struct ProjectHealthSummaryView: View {
    let summary: OverviewSummary
    let onOpenAttention: () -> Void

    private var metrics: [OverviewMetric] {
        [
            OverviewMetric(
                id: "projects",
                label: "Projets",
                value: summary.projectsTotal,
                symbolName: "folder",
                tint: nil,
                isInteractive: false
            ),
            OverviewMetric(
                id: "healthy",
                label: "Sains",
                value: summary.projectsHealthy,
                symbolName: "checkmark.circle",
                tint: summary.projectsHealthy > 0 ? .green : nil,
                isInteractive: false
            ),
            OverviewMetric(
                id: "attention",
                label: "À examiner",
                value: summary.projectsAttention,
                symbolName: "exclamationmark.triangle",
                tint: summary.projectsAttention > 0 ? .orange : nil,
                isInteractive: summary.projectsAttention > 0
            ),
            OverviewMetric(
                id: "error",
                label: "En erreur",
                value: summary.projectsError,
                symbolName: "xmark.octagon",
                tint: summary.projectsError > 0 ? .red : nil,
                isInteractive: summary.projectsError > 0
            )
        ]
    }

    var body: some View {
        SectionSurface(title: "Résumé des projets") {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: Spacing.lg) {
                    ForEach(metrics) { metric in
                        metricView(metric)
                    }
                }
                .frame(minWidth: 640, alignment: .leading)

                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    alignment: .leading,
                    spacing: Spacing.md
                ) {
                    ForEach(metrics) { metric in
                        metricView(metric)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func metricView(_ metric: OverviewMetric) -> some View {
        if metric.isInteractive {
            Button(action: onOpenAttention) {
                MetricItemView(
                    label: metric.label,
                    value: "\(metric.value)",
                    symbolName: metric.symbolName,
                    tint: metric.tint
                )
            }
            .buttonStyle(.plain)
            .help("Ouvrir les projets à examiner")
        } else {
            MetricItemView(
                label: metric.label,
                value: "\(metric.value)",
                symbolName: metric.symbolName,
                tint: metric.tint
            )
        }
    }
}

private struct OverviewMetric: Identifiable {
    let id: String
    let label: String
    let value: Int
    let symbolName: String
    let tint: Color?
    let isInteractive: Bool
}

// MARK: - Required actions and recent activity

struct RequiredActionRow: View {
    let action: OverviewAction
    let open: () -> Void

    var body: some View {
        Button(action: open) {
            HStack(spacing: Spacing.md) {
                Image(systemName: action.severity.symbolName)
                    .foregroundStyle(action.severity == .error ? .red : .orange)

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(action.skill)
                        .font(.body.weight(.medium))
                    Text("\(action.project) · \(action.status.displayName)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: Spacing.md)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.vertical, Spacing.sm)
        .accessibilityLabel(
            "(action.skill) dans (action.project). "
            + "(action.status.displayName). (action.severity.displayName)."
        )
    }
}

struct RecentActivityRow: View {
    let activity: Activity
    let open: () -> Void

    var body: some View {
        Button(action: open) {
            HStack(alignment: .top, spacing: Spacing.md) {
                Image(systemName: activity.status.symbolName)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(activity.status.tint)
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(activity.displayName)
                        .font(.body.weight(.medium))
                        .lineLimit(1)

                    Text(activity.summary.isEmpty ? activity.targetDescription : activity.summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: Spacing.md)

                HStack(spacing: Spacing.xs) {
                    Text(AppFormatters.relativeDate(activity.startedAt))
                    if let duration = activity.duration {
                        Text("·")
                        Text(AppFormatters.duration(duration))
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .padding(.top, 2)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.vertical, Spacing.sm)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "(activity.displayName). (activity.summary). "
            + "(activity.status.displayName), (AppFormatters.relativeDate(activity.startedAt))."
        )
    }
}

private extension SystemState {
    var surfaceTone: SemanticSurfaceTone {
        switch self {
        case .unknown, .checking: return .neutral
        case .healthy: return .success
        case .attention: return .attention
        case .error: return .error
        }
    }
}

#Preview {
    ContentView()
}
