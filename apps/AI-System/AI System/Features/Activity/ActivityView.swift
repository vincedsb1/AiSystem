import AppKit
import SwiftUI

/// Activité — every operation in context: conclusion first, technical output
/// last and collapsed.
struct ActivityView: View {
    @Environment(ActivityStore.self) private var store

    @State private var filter: ActivityFilter = .all
    @State private var searchText = ""

    var body: some View {
        @Bindable var store = store

        HSplitView {
            list
                .frame(minWidth: 280, idealWidth: 340, maxWidth: 460)

            detail
                .frame(minWidth: 380, maxWidth: .infinity)
        }
        .toolbar { toolbarContent }
    }

    private var visibleActivities: [Activity] {
        store.filtered(by: filter, search: searchText)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Picker("Filtre", selection: $filter) {
                ForEach(ActivityFilter.allCases) { option in
                    Text("\(option.displayName) (\(store.count(for: option)))")
                        .tag(option)
                }
            }
            .pickerStyle(.menu)
            .help("Filtrer les activités")
        }
    }

    // MARK: - List

    private var list: some View {
        @Bindable var store = store

        return VStack(spacing: 0) {
            HStack {
                TextField("Rechercher", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel("Rechercher dans les activités")
            }
            .padding(Spacing.related)

            if store.activities.isEmpty {
                EmptyStateView(
                    symbolName: "list.bullet.rectangle",
                    title: "Aucune activité",
                    description: "Les opérations lancées depuis l'application apparaîtront ici."
                )
            } else if visibleActivities.isEmpty {
                EmptyStateView(
                    symbolName: "line.3.horizontal.decrease.circle",
                    title: "Aucun résultat",
                    description: "Aucune activité ne correspond au filtre actuel.",
                    actionLabel: "Effacer le filtre",
                    action: {
                        filter = .all
                        searchText = ""
                    }
                )
            } else {
                List(visibleActivities, selection: $store.selectedActivityId) { activity in
                    ActivityRow(activity: activity)
                        .tag(activity.id)
                }
                .listStyle(.inset)
            }
        }
    }

    // MARK: - Detail

    @ViewBuilder
    private var detail: some View {
        if let activity = store.selectedActivity {
            ActivityDetailView(activity: activity)
        } else {
            EmptyStateView(
                symbolName: "sidebar.left",
                title: "Aucune activité sélectionnée",
                description: "Sélectionnez une activité pour voir son résultat."
            )
        }
    }
}

// MARK: - Row

private struct ActivityRow: View {
    let activity: Activity

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.grouped) {
            Image(systemName: activity.status.symbolName)
                .foregroundStyle(activity.status.tint)
                .frame(width: 18)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(activity.displayName)
                    .font(.body)
                    .lineLimit(1)

                Text(activity.targetDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                if !activity.summary.isEmpty {
                    Text(activity.summary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: Spacing.related)

            VStack(alignment: .trailing, spacing: 2) {
                Text(activity.startedAt, style: .time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let duration = activity.durationDescription {
                    Text(duration)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, Spacing.micro)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(activity.displayName). \(activity.targetDescription). "
            + "\(activity.status.displayName). \(activity.summary)"
        )
    }
}

// MARK: - Detail view

/// Mandatory order (spec 14.5): conclusion, changes, warnings, files,
/// then collapsed technical details.
struct ActivityDetailView: View {
    let activity: Activity

    @State private var showTechnical = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.sectionGap) {
                conclusion

                if let changes = activity.changes, changes.hasChanges || changes.unchanged > 0 {
                    changesSection(changes)
                }

                if let error = activity.error {
                    errorSection(error)
                }

                filesSection
                technicalSection
            }
            .padding(Spacing.standard)
        }
    }

    // MARK: Conclusion

    private var conclusion: some View {
        VStack(alignment: .leading, spacing: Spacing.related) {
            HStack(alignment: .top, spacing: Spacing.grouped) {
                Image(systemName: activity.status.symbolName)
                    .font(.system(size: 22))
                    .foregroundStyle(activity.status.tint)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: Spacing.micro) {
                    Text(activity.displayName)
                        .font(.title3)
                        .fontWeight(.semibold)

                    Text(activity.summary.isEmpty
                         ? activity.status.displayName
                         : activity.summary)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(
                "\(activity.displayName). \(activity.status.displayName). \(activity.summary)"
            )

            HStack(spacing: Spacing.standard) {
                metadata("Cible", activity.targetDescription)
                metadata("Démarré", activity.startedAt.formatted(date: .abbreviated, time: .standard))
                if let duration = activity.durationDescription {
                    metadata("Durée", duration)
                }
            }
        }
    }

    private func metadata(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label) : \(value)")
    }

    // MARK: Changes

    private func changesSection(_ changes: ActionChanges) -> some View {
        VStack(alignment: .leading, spacing: Spacing.related) {
            Text("Changements")
                .font(.headline)

            HStack(spacing: Spacing.sectionGap) {
                countItem("Créés", changes.created)
                countItem("Mis à jour", changes.updated)
                countItem("Inchangés", changes.unchanged)
                if let conflicts = changes.conflicts, conflicts > 0 {
                    countItem("Conflits", conflicts, tint: .red)
                }
            }

            // Unchanged items never produce a long visible list (spec 12.5).
            if let blocked = changes.blocked, !blocked.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.micro) {
                    Text("Non résolus")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ForEach(blocked) { item in
                        Text("• \(item.skill) — \(item.status.displayName)")
                            .font(.caption)
                    }
                }
            }
        }
    }

    private func countItem(_ label: String, _ value: Int, tint: Color? = nil) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text("\(value)")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(tint ?? .primary)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label) : \(value)")
    }

    // MARK: Error

    private func errorSection(_ error: ActivityError) -> some View {
        VStack(alignment: .leading, spacing: Spacing.related) {
            Text("Erreur")
                .font(.headline)

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

    // MARK: Files

    private var filesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.related) {
            Text("Rapports et fichiers")
                .font(.headline)

            HStack(spacing: Spacing.grouped) {
                Button("Ouvrir Inventory") { open("open-inventory") }
                Button("Ouvrir Doctor") { open("open-doctor") }
                Button("Ouvrir le log") { open("open-log") }
                    .disabled(activity.technical == nil)
            }
            .controlSize(.small)
        }
    }

    // MARK: Technical

    private var technicalSection: some View {
        VStack(alignment: .leading, spacing: Spacing.related) {
            if let technical = activity.technical {
                // Collapsed by default (FR-ACT-02).
                DisclosureGroup("Détails techniques", isExpanded: $showTechnical) {
                    VStack(alignment: .leading, spacing: Spacing.grouped) {
                        technicalRow("Action backend", technical.action)
                        if !technical.arguments.isEmpty {
                            technicalRow("Arguments", technical.arguments.joined(separator: " "))
                        }
                        technicalRow("Code de sortie", "\(technical.exitCode)")
                        technicalRow("Chemin du log", technical.logPath)

                        if !technical.stdout.isEmpty {
                            streamBlock("stdout", technical.stdout)
                        }
                        if !technical.stderr.isEmpty {
                            streamBlock("stderr", technical.stderr)
                        }

                        HStack(spacing: Spacing.grouped) {
                            Button("Copier les détails") {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(
                                    technical.copyableText, forType: .string
                                )
                            }
                            Button("Ouvrir le fichier log") { open("open-log") }
                        }
                        .controlSize(.small)
                        .padding(.top, Spacing.micro)
                    }
                    .padding(.top, Spacing.related)
                }
                .font(.headline)
            } else {
                Text("Aucun détail technique disponible pour cette activité.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func technicalRow(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            // Monospaced type is reserved for this section (FR-ACT-01).
            Text(value)
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func streamBlock(_ label: String, _ content: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.micro) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)

            ScrollView(.horizontal) {
                Text(content)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 180)
            .padding(Spacing.related)
            .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 6))
        }
    }

    private func open(_ action: String) {
        Task { await ProjectSkillsService().openResource(action) }
    }
}
