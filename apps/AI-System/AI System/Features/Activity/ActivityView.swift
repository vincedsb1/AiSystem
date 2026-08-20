import AppKit
import SwiftUI

/// Activité — the list answers "what happened"; the detail answers "what was
/// the result" before exposing technical evidence.
struct ActivityView: View {
    @Environment(ActivityStore.self) private var store

    @State private var filter: ActivityFilter = .all
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        HSplitView {
            activityList
                .frame(minWidth: 280, idealWidth: 350, maxWidth: 440)

            detail
                .frame(minWidth: 380, maxWidth: .infinity)
        }
        .onReceive(NotificationCenter.default.publisher(for: .searchRequested)) { _ in
            isSearchFocused = true
        }
    }

    private var detail: some View {
        @Bindable var store = store

        return Group {
            if let activity = store.selectedActivity {
                ActivityDetailView(activity: activity)
                    .id(activity.id)
            } else {
                EmptyStateView(
                    symbolName: "sidebar.left",
                    title: "Aucune activité sélectionnée",
                    description: "Sélectionnez une activité pour voir son résultat."
                )
            }
        }
    }

    // MARK: List

    private var activityList: some View {
        @Bindable var store = store
        let groups = store.grouped(by: filter, search: searchText)

        return VStack(alignment: .leading, spacing: 0) {
            listHeader(store: store)

            if store.activities.isEmpty {
                EmptyStateView(
                    symbolName: "list.bullet.rectangle",
                    title: "Aucune activité",
                    description: "Les opérations lancées depuis l’application apparaîtront ici."
                )
            } else if groups.isEmpty {
                EmptyStateView(
                    symbolName: "line.3.horizontal.decrease.circle",
                    title: "Aucun résultat",
                    description: "Aucune activité ne correspond au filtre ou à la recherche.",
                    actionLabel: "Effacer les critères",
                    action: {
                        filter = .all
                        searchText = ""
                    }
                )
            } else {
                List(selection: $store.selectedActivityId) {
                    ForEach(groups) { group in
                        Section {
                            ForEach(group.activities) { activity in
                                ActivityListRow(activity: activity)
                                    .tag(activity.id)
                            }
                        } header: {
                            if !group.title.isEmpty {
                                Text(group.title)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .textCase(nil)
                            }
                        }
                    }
                }
                .listStyle(.inset)
            }
        }
    }

    private func listHeader(store: ActivityStore) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(alignment: .firstTextBaseline) {
                Text("Activité")
                    .font(.title2.weight(.semibold))
                Spacer()
                Text("\(store.filtered(by: filter, search: searchText).count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Nombre d’activités")
            }

            HStack(spacing: Spacing.sm) {
                TextField("Rechercher", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .focused($isSearchFocused)
                    .accessibilityLabel("Rechercher dans les activités")

                Picker("Filtrer", selection: $filter) {
                    ForEach(ActivityFilter.allCases) { option in
                        Text("\(option.displayName) (\(store.count(for: option)))")
                            .tag(option)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 154, alignment: .trailing)
                .accessibilityLabel("Filtrer les activités")
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.md)
        .padding(.bottom, Spacing.sm)
    }
}

// MARK: - List row

private struct ActivityListRow: View {
    let activity: Activity

    var body: some View {
        HStack(alignment: .center, spacing: Spacing.sm) {
            Image(systemName: activity.status.symbolName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(activity.status.tint)
                .frame(width: 18)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(activity.displayName)
                    .font(.body.weight(.semibold))
                    .lineLimit(1)
                    .truncationMode(.middle)

                Text(activity.targetDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)

                if !activity.summary.isEmpty {
                    Text(activity.summary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: Spacing.sm)

            VStack(alignment: .trailing, spacing: Spacing.xxs) {
                Text(AppFormatters.time(activity.startedAt))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let duration = activity.durationDescription {
                    Text(duration)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .fixedSize(horizontal: true, vertical: false)
        }
        .frame(minHeight: 62, alignment: .center)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    private var accessibilityDescription: String {
        [
            activity.displayName,
            activity.targetDescription,
            activity.summary.isEmpty ? nil : activity.summary,
            activity.status.displayName,
            AppFormatters.time(activity.startedAt),
            activity.durationDescription
        ]
        .compactMap { $0 }
        .joined(separator: ". ")
    }
}

// MARK: - Detail

/// Mandatory order: result, changes/warnings, resources, then collapsed
/// technical details.
struct ActivityDetailView: View {
    let activity: Activity

    @State private var showTechnical = false

    var body: some View {
        ScrollView {
            AdaptiveContentContainer(maxWidth: 820) {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    detailHeader
                    resultSection

                    if let changes = activity.changes,
                       changes.hasChanges || changes.unchanged > 0 {
                        changesSection(changes)
                    }

                    if let error = activity.error {
                        errorSection(error)
                    }

                    resourcesSection
                    technicalSection
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: Header

    private var detailHeader: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(alignment: .top, spacing: Spacing.md) {
                ZStack {
                    Circle()
                        .fill(activity.status.tint.opacity(0.13))
                    Image(systemName: activity.status.symbolName)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(activity.status.tint)
                }
                .frame(width: 42, height: 42)
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(activity.displayName)
                        .font(.title2.weight(.semibold))
                        .lineLimit(2)

                    Text(activity.status.activityDisplayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(activity.status.tint)
                }

                Spacer(minLength: 0)
            }

            if !activity.summary.isEmpty {
                Text(activity.summary)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text(metadataLine)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(activity.displayName). \(activity.status.activityDisplayName). "
            + "\(activity.summary). \(metadataLine)"
        )
        .padding(.bottom, Spacing.sm)
    }

    private var metadataLine: String {
        var values = [AppFormatters.observationDate(activity.startedAt)]
        if let duration = activity.durationDescription {
            values.append(duration)
        }
        values.append(activity.targetDescription)
        return values.joined(separator: " · ")
    }

    // MARK: Result

    private var resultSection: some View {
        SectionSurface(title: "Résultat", tone: resultTone) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(activity.summary.isEmpty
                     ? activity.status.activityDisplayName
                     : activity.summary)
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)

                if activity.warningCount > 0 {
                    Label(
                        "\(activity.warningCount) avertissement\(activity.warningCount == 1 ? "" : "s")",
                        systemImage: "exclamationmark.triangle"
                    )
                    .font(.subheadline)
                    .foregroundStyle(.orange)
                }

                if let changes = activity.changes,
                   changes.hasChanges || changes.unchanged > 0 {
                    HStack(spacing: Spacing.lg) {
                        resultMetric("Créés", changes.created)
                        resultMetric("Mis à jour", changes.updated)
                        resultMetric("Inchangés", changes.unchanged)
                        if let conflicts = changes.conflicts, conflicts > 0 {
                            resultMetric("Conflits", conflicts, tint: .red)
                        }
                    }
                }
            }
        }
    }

    private func resultMetric(_ label: String, _ value: Int, tint: Color? = nil) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text("\(value)")
                .font(.title3.weight(.semibold))
                .foregroundStyle(tint ?? .primary)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label) : \(value)")
    }

    private var resultTone: SemanticSurfaceTone {
        switch activity.status {
        case .succeeded: return .success
        case .partiallySucceeded: return .attention
        case .failed: return .error
        default: return .neutral
        }
    }

    // MARK: Changes and errors

    private func changesSection(_ changes: ActionChanges) -> some View {
        SectionSurface(title: "Changements") {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack(spacing: Spacing.lg) {
                    resultMetric("Créés", changes.created)
                    resultMetric("Mis à jour", changes.updated)
                    resultMetric("Inchangés", changes.unchanged)
                    if let conflicts = changes.conflicts, conflicts > 0 {
                        resultMetric("Conflits", conflicts, tint: .red)
                    }
                }

                if let blocked = changes.blocked, !blocked.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text("Non résolus")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        ForEach(blocked) { item in
                            Text("• \(item.skill) — \(item.status.displayName)")
                                .font(.caption)
                        }
                    }
                }
            }
        }
    }

    private func errorSection(_ error: ActivityError) -> some View {
        SectionSurface(title: "Erreur", tone: .error) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                InlineFeedbackView(type: .error, message: error.message)

                if let writeState = error.writeStateDescription {
                    Text(writeState)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                if let code = error.code {
                    Text("Code : \(code)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: Resources

    private var resourcesSection: some View {
        SectionSurface(
            title: "Rapports et fichiers",
            subtitle: "Ouvrir les sorties produites par cette activité."
        ) {
            VStack(spacing: 0) {
                ActivityResourceRow(
                    symbolName: "shippingbox",
                    title: "Inventory",
                    subtitle: "État des projets et des skills",
                    action: { open("open-inventory") }
                )
                Divider()
                ActivityResourceRow(
                    symbolName: "stethoscope",
                    title: "Doctor",
                    subtitle: "Diagnostic et anomalies",
                    action: { open("open-doctor") }
                )
                Divider()
                ActivityResourceRow(
                    symbolName: "doc.text",
                    title: "Journal",
                    subtitle: "Sortie technique de l’opération",
                    isEnabled: activity.technical != nil,
                    action: { open("open-log") }
                )
            }
        }
    }

    // MARK: Technical

    @ViewBuilder
    private var technicalSection: some View {
        if let technical = activity.technical {
            SectionSurface {
                DisclosureGroup(isExpanded: $showTechnical) {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        technicalGrid(technical)

                        if !technical.stdout.isEmpty {
                            streamBlock("stdout", technical.stdout)
                        }
                        if !technical.stderr.isEmpty {
                            streamBlock("stderr", technical.stderr)
                        }

                        HStack(spacing: Spacing.sm) {
                            Button {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(
                                    technical.copyableText,
                                    forType: .string
                                )
                            } label: {
                                Label("Copier les détails", systemImage: "doc.on.doc")
                            }

                            Button {
                                open("open-log")
                            } label: {
                                Label("Ouvrir le journal", systemImage: "arrow.up.right.square")
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    .padding(.top, Spacing.sm)
                } label: {
                    Label("Détails techniques", systemImage: "terminal")
                        .font(.headline)
                }
            }
        }
    }

    private func technicalGrid(_ technical: TechnicalDetails) -> some View {
        Grid(
            alignment: .leading,
            horizontalSpacing: Spacing.md,
            verticalSpacing: Spacing.xs
        ) {
            GridRow {
                technicalLabel("Action backend")
                technicalValue(technical.action)
            }
            if !technical.arguments.isEmpty {
                GridRow {
                    technicalLabel("Arguments")
                    technicalValue(technical.arguments.joined(separator: " "))
                }
            }
            GridRow {
                technicalLabel("Code de sortie")
                technicalValue("\(technical.exitCode)")
            }
            GridRow {
                technicalLabel("Chemin du log")
                technicalValue(technical.logPath)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func technicalLabel(_ value: String) -> some View {
        Text(value)
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    private func technicalValue(_ value: String) -> some View {
        Text(value)
            .font(.system(.caption, design: .monospaced))
            .textSelection(.enabled)
    }

    private func streamBlock(_ label: String, _ content: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                Text(content)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 160)
            .padding(Spacing.md)
            .background(
                Color(nsColor: .textBackgroundColor).opacity(0.55),
                in: RoundedRectangle(cornerRadius: AppRadius.compact, style: .continuous)
            )
        }
    }

    private func open(_ action: String) {
        Task { await ProjectSkillsService().openResource(action) }
    }
}

private struct ActivityResourceRow: View {
    let symbolName: String
    let title: String
    let subtitle: String
    var isEnabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: symbolName)
                    .font(.body.weight(.medium))
                    .foregroundStyle(isEnabled ? Color.accentColor : Color.secondary)
                    .frame(width: 22)

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(title)
                        .font(.body.weight(.medium))
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: Spacing.sm)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.55)
        .accessibilityLabel("\(title). \(subtitle)")
    }
}

private extension OperationStatus {
    var activityDisplayName: String {
        switch self {
        case .queued: return "En attente"
        case .running: return "En cours"
        case .succeeded: return "Réussie"
        case .partiallySucceeded: return "Réussie avec avertissements"
        case .failed: return "Échouée"
        case .cancelled: return "Annulée"
        }
    }
}

#Preview {
    ContentView()
}
