import Foundation
import Observation

/// Stable presentation state for the operation currently visible across the
/// application. The backend remains authoritative for business outcomes;
/// this model only describes the UI lifecycle of a command already launched.
struct ActiveOperation: Identifiable, Equatable {
    let id: UUID
    let activityID: UUID?
    let kind: ActivityKind
    let displayName: String
    let target: String
    let startedAt: Date
    let cancellable: Bool
    let progress: Double?
    var state: OperationStatus
    var finishedAt: Date?
    var headline: String
    var statusMessage: String?

    var isRunning: Bool {
        state == .queued || state == .running
    }

    func elapsed(at date: Date = Date()) -> TimeInterval {
        let end = finishedAt ?? date
        return max(0, end.timeIntervalSince(startedAt))
    }
}

/// Single source of truth for the operation visible in the global toolbar.
/// Feature view models may keep local loading state for their own stale-data
/// rules, but they must use this object for cross-destination operations.
@MainActor
@Observable
final class CommandCenter {
    private(set) var currentOperation: ActiveOperation?

    @ObservationIgnored
    private var dismissalTask: Task<Void, Never>?

    var isRunning: Bool {
        currentOperation?.isRunning == true
    }

    var canStart: Bool {
        !isRunning
    }

    @discardableResult
    func begin(
        kind: ActivityKind,
        displayName: String,
        target: String,
        activityID: UUID? = nil,
        cancellable: Bool = false,
        startedAt: Date = Date()
    ) -> UUID? {
        guard canStart else { return nil }

        dismissalTask?.cancel()
        let id = UUID()
        currentOperation = ActiveOperation(
            id: id,
            activityID: activityID,
            kind: kind,
            displayName: displayName,
            target: target,
            startedAt: startedAt,
            cancellable: cancellable,
            progress: nil,
            state: .running,
            finishedAt: nil,
            headline: "\(displayName)…",
            statusMessage: nil
        )
        return id
    }

    func update(
        operationID: UUID,
        statusMessage: String? = nil,
        progress: Double? = nil
    ) {
        guard var operation = currentOperation, operation.id == operationID else { return }
        operation.statusMessage = statusMessage
        operation = ActiveOperation(
            id: operation.id,
            activityID: operation.activityID,
            kind: operation.kind,
            displayName: operation.displayName,
            target: operation.target,
            startedAt: operation.startedAt,
            cancellable: operation.cancellable,
            progress: progress,
            state: operation.state,
            finishedAt: operation.finishedAt,
            headline: operation.headline,
            statusMessage: statusMessage
        )
        currentOperation = operation
    }

    func finish(
        operationID: UUID,
        status: OperationStatus,
        headline: String,
        statusMessage: String? = nil,
        finishedAt: Date = Date()
    ) {
        guard let operation = currentOperation, operation.id == operationID else { return }

        currentOperation = ActiveOperation(
            id: operation.id,
            activityID: operation.activityID,
            kind: operation.kind,
            displayName: operation.displayName,
            target: operation.target,
            startedAt: operation.startedAt,
            cancellable: operation.cancellable,
            progress: operation.progress,
            state: status,
            finishedAt: finishedAt,
            headline: headline,
            statusMessage: statusMessage
        )

        if status == .succeeded || status == .partiallySucceeded || status == .cancelled {
            scheduleDismissal(for: operationID)
        } else {
            dismissalTask?.cancel()
            dismissalTask = nil
        }
    }

    func dismiss(operationID: UUID? = nil) {
        guard operationID == nil || operationID == currentOperation?.id else { return }
        dismissalTask?.cancel()
        dismissalTask = nil
        currentOperation = nil
    }

    private func scheduleDismissal(for operationID: UUID) {
        dismissalTask?.cancel()
        dismissalTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                guard let self,
                      self.currentOperation?.id == operationID,
                      self.currentOperation?.state != .failed
                else { return }
                self.currentOperation = nil
                self.dismissalTask = nil
            }
        }
    }
}
