import Foundation

/// Durable, session-scoped semantic summary of one completed operation.
/// Every value is supplied by structured payloads, known context or the
/// CommandResult envelope; stdout is never interpreted here.
struct OperationReceipt: Identifiable, Equatable {
    let id: UUID
    let operationID: UUID
    let kind: ActivityKind
    let target: String
    let status: OperationStatus
    let startedAt: Date
    let finishedAt: Date
    let duration: TimeInterval
    let headline: String
    let summary: String
    let createdCount: Int?
    let updatedCount: Int?
    let unchangedCount: Int?
    let warningCount: Int?
    let errorCount: Int?
    let actionRequiredCount: Int?
    let resources: [OperationResource]
    let technicalReference: String?
}

struct OperationResource: Identifiable, Equatable {
    let id: String
    let title: String
    let action: String
}

enum OperationReceiptBuilder {
    static func build(from activity: Activity) -> OperationReceipt? {
        guard let finishedAt = activity.finishedAt else { return nil }

        return OperationReceipt(
            id: activity.id,
            operationID: activity.id,
            kind: activity.kind,
            target: activity.targetDescription,
            status: activity.status,
            startedAt: activity.startedAt,
            finishedAt: finishedAt,
            duration: max(0, finishedAt.timeIntervalSince(activity.startedAt)),
            headline: headline(for: activity),
            summary: activity.summary,
            createdCount: activity.changes?.created,
            updatedCount: activity.changes?.updated,
            unchangedCount: activity.changes?.unchanged,
            warningCount: activity.warningCount > 0 ? activity.warningCount : nil,
            errorCount: activity.error == nil ? nil : 1,
            actionRequiredCount: nil,
            resources: resources(for: activity),
            technicalReference: activity.technical?.logPath
        )
    }

    static func headline(for activity: Activity) -> String {
        switch activity.status {
        case .failed:
            return "\(activity.displayName) a échoué"
        case .partiallySucceeded:
            return "\(activity.displayName) terminé avec avertissements"
        case .cancelled:
            return "\(activity.displayName) annulé"
        case .running, .queued:
            return "\(activity.displayName)…"
        case .succeeded:
            switch activity.kind {
            case .check:
                return activity.summary.localizedCaseInsensitiveContains("aucune action")
                    ? "Tout est à jour"
                    : "Vérification terminée"
            case .sync:
                return "\(activity.targetDescription) synchronisé"
            case .importSkill:
                return activity.skillId.map { "\($0) est maintenant géré" }
                    ?? "Import terminé"
            case .addProject:
                return "\(activity.targetDescription) est maintenant géré"
            case .scan:
                return "Analyse de \(activity.targetDescription) terminée"
            case .tool:
                return "\(activity.displayName) terminé"
            }
        }
    }

    private static func resources(for activity: Activity) -> [OperationResource] {
        var resources = [
            OperationResource(
                id: "inventory",
                title: "Inventory",
                action: "open-inventory"
            ),
            OperationResource(
                id: "doctor",
                title: "Doctor",
                action: "open-doctor"
            )
        ]

        if activity.technical != nil {
            resources.append(
                OperationResource(
                    id: "log",
                    title: "Journal",
                    action: "open-log"
                )
            )
        }
        return resources
    }
}
