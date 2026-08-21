import SwiftUI

/// Compact global operation control. It never displays stdout and stays
/// available while the user navigates between the main destinations.
struct OperationStatusControl: View {
    /// The toolbar lives on a modifier boundary, so the authority is passed
    /// explicitly instead of relying on environment propagation into toolbar
    /// content.
    let commandCenter: CommandCenter
    let onOpenActivity: (UUID) -> Void
    @State private var showPopover = false

    var body: some View {
        if let operation = commandCenter.currentOperation {
            Button {
                showPopover = true
            } label: {
                HStack(spacing: Spacing.xs) {
                    statusIcon(operation)
                    Text(operation.headline)
                        .font(.caption)
                        .lineLimit(1)
                }
            }
            .buttonStyle(.borderless)
            .help(operation.statusMessage ?? operation.headline)
            .accessibilityLabel(accessibilityLabel(for: operation))
            .popover(isPresented: $showPopover, arrowEdge: .bottom) {
                OperationStatusPopover(
                    operation: operation,
                    onOpenActivity: {
                        showPopover = false
                        if let activityID = operation.activityID {
                            onOpenActivity(activityID)
                            commandCenter.dismiss(operationID: operation.id)
                        }
                    },
                    onDismiss: {
                        showPopover = false
                        commandCenter.dismiss(operationID: operation.id)
                    }
                )
            }
            .onChange(of: operation.id) { _, _ in
                showPopover = false
            }
        }
    }

    @ViewBuilder
    private func statusIcon(_ operation: ActiveOperation) -> some View {
        if operation.isRunning {
            ProgressView()
                .controlSize(.small)
        } else {
            Image(systemName: operation.state.symbolName)
                .foregroundStyle(operation.state.tint)
        }
    }

    private func accessibilityLabel(for operation: ActiveOperation) -> String {
        [
            operation.headline,
            operation.target,
            operation.state.displayName,
            operation.statusMessage
        ]
        .compactMap { $0 }
        .joined(separator: ". ")
    }
}

private struct OperationStatusPopover: View {
    let operation: ActiveOperation
    let onOpenActivity: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(alignment: .top, spacing: Spacing.sm) {
                Image(systemName: operation.state.symbolName)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(operation.state.tint)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(operation.headline)
                        .font(.headline)
                    Text(operation.target)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            detailRow("État", operation.state.displayName)
            if operation.isRunning {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    detailRow("Durée", AppFormatters.duration(operation.elapsed(at: context.date)))
                }
            } else {
                detailRow("Durée", AppFormatters.duration(operation.elapsed()))
            }

            if let message = operation.statusMessage {
                Text(message)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack {
                if operation.activityID != nil {
                    Button("Voir dans Activité", action: onOpenActivity)
                        .buttonStyle(.borderedProminent)
                }

                if !operation.isRunning {
                    Button("Fermer", action: onDismiss)
                        .buttonStyle(.borderless)
                }
            }
        }
        .padding(Spacing.lg)
        .frame(width: 330, alignment: .leading)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(
            [operation.headline, operation.target, operation.state.displayName, operation.statusMessage]
                .compactMap { $0 }
                .joined(separator: ". ")
        )
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.callout)
        }
    }
}

#Preview("Operation Experience") {
    OperationStatusControl(commandCenter: CommandCenter(), onOpenActivity: { _ in })
        .padding()
}
