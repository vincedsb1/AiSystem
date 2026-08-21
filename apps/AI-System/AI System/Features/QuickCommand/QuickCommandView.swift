import SwiftUI

struct QuickCommandView: View {
    let activityStore: ActivityStore
    let dataStore: AppDataStore
    let commandCenter: CommandCenter
    @FocusState private var searchFocused: Bool
    @State private var model = QuickCommandViewModel()

    let onIntent: (QuickCommandIntent) -> Void
    let onDismiss: () -> Void

    var body: some View {
        let results = model.results(for: context)

        VStack(alignment: .leading, spacing: 0) {
            searchField
            Divider()

            if results.isEmpty {
                EmptyStateView(
                    symbolName: "magnifyingglass",
                    title: model.query.isEmpty ? "Aucune commande disponible" : "Aucun résultat",
                    description: model.query.isEmpty
                        ? "Les commandes statiques apparaîtront ici."
                        : "Aucun résultat pour “\(model.query)”",
                    actionLabel: model.query.isEmpty ? nil : "Effacer la recherche",
                    action: model.query.isEmpty ? nil : { model.reset() }
                )
                .frame(minHeight: 220)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(results.enumerated()), id: \.element.id) { index, item in
                                QuickCommandRow(
                                    item: item,
                                    isSelected: index == model.selectedIndex,
                                    action: { perform(item) }
                                )
                                .id(item.id)
                            }
                        }
                        .padding(.vertical, Spacing.xs)
                    }
                    .frame(maxHeight: 390)
                    .onChange(of: model.selectedIndex) { _, index in
                        guard results.indices.contains(index) else { return }
                        withAnimation(.easeOut(duration: 0.12)) {
                            proxy.scrollTo(results[index].id, anchor: .center)
                        }
                    }
                }
            }

            Divider()
            footer
        }
        .frame(width: 680)
        .frame(maxHeight: 520)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.hero, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.hero, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.12), lineWidth: 1)
        }
        .onAppear {
            model.reset()
            searchFocused = true
        }
        .onChange(of: model.query) { _, _ in
            model.selectFirst()
        }
        .onMoveCommand { direction in
            switch direction {
            case .up: model.moveSelection(by: -1, resultCount: results.count)
            case .down: model.moveSelection(by: 1, resultCount: results.count)
            default: break
            }
        }
        .onExitCommand(perform: onDismiss)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Quick Command. Rechercher une commande, un projet, un skill ou une activité.")
    }

    private var context: QuickCommandContext {
        QuickCommandContext(
            activeSection: dataStore.activeSection,
            selectedProjectName: dataStore.selectedProjectName,
            projects: dataStore.projects,
            skills: dataStore.skills,
            activities: activityStore.activities,
            operationIsRunning: commandCenter.isRunning
        )
    }

    private var searchField: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "command")
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            TextField("Rechercher une commande…", text: $model.query)
                .textFieldStyle(.plain)
                .font(.title3)
                .focused($searchFocused)
                .onSubmit {
                    let results = model.results(for: context)
                    if let item = model.selectedItem(from: results) {
                        perform(item)
                    }
                }
                .accessibilityLabel("Rechercher une commande")

            if !model.query.isEmpty {
                Button("Effacer") { model.query = "" }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Effacer la recherche")
            }
        }
        .padding(Spacing.md)
    }

    private var footer: some View {
        HStack(spacing: Spacing.md) {
            Text("↑↓ Naviguer")
            Text("Retour Ouvrir")
            Spacer()
            Text("Échap Fermer")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
    }

    private func perform(_ item: QuickCommandItem) {
        guard item.availability.isAvailable else { return }
        model.remember(item)
        onIntent(item.intent)
    }
}

private struct QuickCommandRow: View {
    let item: QuickCommandItem
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: item.systemImage)
                    .font(.body.weight(.medium))
                    .foregroundStyle(item.availability.isAvailable ? Color.accentColor : Color.secondary)
                    .frame(width: 24)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(item.title)
                        .font(.body.weight(.medium))
                        .lineLimit(1)
                    Text(item.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer(minLength: Spacing.sm)

                Text(item.kind.displayName)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                if let explanation = item.availability.explanation {
                    Image(systemName: "lock")
                        .foregroundStyle(.secondary)
                        .help(explanation)
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(
                isSelected ? Color.accentColor.opacity(0.14) : Color.clear,
                in: RoundedRectangle(cornerRadius: AppRadius.compact, style: .continuous)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!item.availability.isAvailable)
        .padding(.horizontal, Spacing.xs)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(isSelected ? "Sélectionné" : "")
    }

    private var accessibilityLabel: String {
        var values = [item.title, item.subtitle]
        if let explanation = item.availability.explanation {
            values.append(explanation)
        }
        return values.joined(separator: ". ")
    }
}

#Preview("Quick Command") {
    QuickCommandView(
        activityStore: ActivityStore(),
        dataStore: AppDataStore(),
        commandCenter: CommandCenter(),
        onIntent: { _ in },
        onDismiss: {}
    )
        .padding()
}
