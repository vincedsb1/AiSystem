import Foundation
import Observation

/// Session-scoped activity history shared by every destination.
///
/// This replaces the single global `lastResult`: each caller keeps its own
/// result, and the store holds the contextualised record (spec 20.5).
@MainActor
@Observable
final class ActivityStore {
    /// Most recent first.
    private(set) var activities: [Activity] = []

    /// Activity selected in the Activity destination, or handed over from an
    /// inline error (FR-NAV-03).
    var selectedActivityId: UUID?

    private let limit: Int

    init(limit: Int = 200) {
        self.limit = limit
    }

    // MARK: - Recording

    /// Registers a running operation and returns its identifier.
    @discardableResult
    func begin(
        kind: ActivityKind,
        displayName: String,
        scope: ActivityScope,
        startedAt: Date = Date()
    ) -> UUID {
        let activity = Activity(
            kind: kind,
            displayName: displayName,
            scope: scope,
            startedAt: startedAt
        )
        activities.insert(activity, at: 0)
        if activities.count > limit {
            activities.removeLast(activities.count - limit)
        }
        return activity.id
    }

    /// Completes an operation with its outcome.
    func finish(
        _ id: UUID,
        status: OperationStatus,
        summary: String,
        changes: ActionChanges? = nil,
        warningCount: Int = 0,
        error: ActivityError? = nil,
        technical: TechnicalDetails? = nil
    ) {
        guard let index = activities.firstIndex(where: { $0.id == id }) else { return }
        activities[index].status = status
        activities[index].finishedAt = Date()
        activities[index].summary = summary
        activities[index].changes = changes
        activities[index].warningCount = warningCount
        activities[index].error = error
        activities[index].technical = technical
        activities[index].receipt = OperationReceiptBuilder.build(from: activities[index])
    }

    // MARK: - Reading

    func activity(_ id: UUID) -> Activity? {
        activities.first { $0.id == id }
    }

    var selectedActivity: Activity? {
        guard let selectedActivityId else { return nil }
        return activity(selectedActivityId)
    }

    /// Three to five most recent entries, for the Overview (spec 9.3).
    func recent(_ count: Int = 5) -> [Activity] {
        Array(activities.prefix(count))
    }

    func filtered(by filter: ActivityFilter, search: String) -> [Activity] {
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines)
        return activities.filter { activity in
            guard filter.matches(activity) else { return false }
            guard !query.isEmpty else { return true }
            return activity.displayName.localizedCaseInsensitiveContains(query)
                || activity.targetDescription.localizedCaseInsensitiveContains(query)
                || activity.summary.localizedCaseInsensitiveContains(query)
        }
    }

    func count(for filter: ActivityFilter) -> Int {
        activities.filter(filter.matches).count
    }

    /// Groups the current filtered collection only when it contains more than
    /// one activity, keeping a single entry visually compact.
    func grouped(
        by filter: ActivityFilter,
        search: String,
        now: Date = Date()
    ) -> [ActivityGroup] {
        let matching = filtered(by: filter, search: search)
        guard matching.count > 1 else {
            return matching.map {
                ActivityGroup(id: "all", title: "", activities: [$0])
            }
        }

        let grouped = Dictionary(grouping: matching) {
            ActivityPeriod.resolve(date: $0.startedAt, now: now)
        }

        return ActivityPeriod.allCases.compactMap { period in
            guard let activities = grouped[period], !activities.isEmpty else {
                return nil
            }
            return ActivityGroup(
                id: period.id,
                title: period.displayName,
                activities: activities
            )
        }
    }

    /// Selects the most recent activity matching a project and skill, so an
    /// inline error can open its own record (FR-NAV-03).
    func selectMostRecent(project: String?, skill: String?) {
        let match = activities.first { activity in
            (project == nil || activity.projectId == project)
                && (skill == nil || activity.skillId == skill)
        }
        selectedActivityId = match?.id
    }
}
