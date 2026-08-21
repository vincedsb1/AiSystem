import Foundation
import Observation

struct QuickCommandRecentStore {
    private let defaults: UserDefaults
    private let key = "ai.system.quickCommand.recent"

    nonisolated init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    nonisolated var ids: [String] {
        defaults.stringArray(forKey: key) ?? []
    }

    nonisolated func remember(_ id: String) {
        var values = ids.filter { $0 != id }
        values.insert(id, at: 0)
        defaults.set(Array(values.prefix(5)), forKey: key)
    }
}

enum QuickCommandSearchIndex {
    nonisolated static func normalize(_ value: String) -> String {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    nonisolated static func ranked(
        _ items: [QuickCommandItem],
        query: String,
        recentIDs: [String],
        activeSection: AppSection
    ) -> [QuickCommandItem] {
        let normalizedQuery = normalize(query)
        guard !normalizedQuery.isEmpty else {
            return emptyQueryOrder(items, recentIDs: recentIDs)
        }

        let recentRank = Dictionary(uniqueKeysWithValues: recentIDs.enumerated().map {
            ($1, max(0, 5 - $0))
        })

        return items
            .compactMap { item -> (QuickCommandItem, Int)? in
                guard let base = score(item, query: normalizedQuery) else { return nil }
                var total = base
                total += recentRank[item.id] ?? 0
                if isInActiveSection(item.intent, activeSection: activeSection) {
                    total += 2
                }
                return (item, total)
            }
            .sorted {
                if $0.1 != $1.1 { return $0.1 > $1.1 }
                return $0.0.title.localizedCaseInsensitiveCompare($1.0.title) == .orderedAscending
            }
            .map(\.0)
    }

    private nonisolated static func emptyQueryOrder(
        _ items: [QuickCommandItem],
        recentIDs: [String]
    ) -> [QuickCommandItem] {
        var result: [QuickCommandItem] = []
        let suggested = items.filter { $0.kind == .action }.prefix(3)
        result.append(contentsOf: suggested)

        for id in recentIDs.prefix(5) {
            guard let item = items.first(where: { $0.id == id }), !result.contains(item) else { continue }
            result.append(item)
        }
        return result
    }

    private nonisolated static func score(_ item: QuickCommandItem, query: String) -> Int? {
        let title = normalize(item.title)
        let subtitle = normalize(item.subtitle)
        let keywords = item.keywords.map(normalize)
        let aliases = item.aliases.map(normalize)

        if title == query { return 1000 }
        if title.hasPrefix(query) { return 900 }
        if title.split(separator: " ").contains(where: { String($0) == query }) { return 800 }
        if title.contains(query) { return 700 }
        if aliases.contains(query) { return 600 }
        if keywords.contains(query) { return 580 }
        if aliases.contains(where: { $0.contains(query) }) { return 550 }
        if subtitle.contains(query) || keywords.contains(where: { $0.contains(query) }) {
            return 500
        }
        return nil
    }

    private nonisolated static func isInActiveSection(
        _ intent: QuickCommandIntent,
        activeSection: AppSection
    ) -> Bool {
        switch intent {
        case .navigate(let section): return section == activeSection
        case .openProject, .revealSkill:
            return activeSection == .projects
        case .openActivity: return activeSection == .activity
        default: return false
        }
    }
}

@MainActor
@Observable
final class QuickCommandViewModel {
    var query = ""
    private(set) var selectedIndex = 0

    private let recentStore: QuickCommandRecentStore

    init(recentStore: QuickCommandRecentStore = QuickCommandRecentStore()) {
        self.recentStore = recentStore
    }

    func results(for context: QuickCommandContext) -> [QuickCommandItem] {
        let items = QuickCommandRegistry.items(context: context)
        return QuickCommandSearchIndex.ranked(
            items,
            query: query,
            recentIDs: recentStore.ids,
            activeSection: context.activeSection
        )
    }

    func reset() {
        query = ""
        selectedIndex = 0
    }

    func moveSelection(by offset: Int, resultCount: Int) {
        guard resultCount > 0 else {
            selectedIndex = 0
            return
        }
        selectedIndex = (selectedIndex + offset + resultCount) % resultCount
    }

    func selectFirst() {
        selectedIndex = 0
    }

    func remember(_ item: QuickCommandItem) {
        recentStore.remember(item.id)
    }

    func selectedItem(from results: [QuickCommandItem]) -> QuickCommandItem? {
        guard results.indices.contains(selectedIndex) else { return nil }
        return results[selectedIndex]
    }
}
