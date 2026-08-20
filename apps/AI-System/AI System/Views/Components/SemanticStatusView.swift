import SwiftUI

// MARK: - Semantic Status Badge

/// Displays a system state with icon, text, and color.
struct SystemStatusView: View {
    let state: SystemState
    let lastCheckedAt: String?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: state.symbolName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(stateColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(state.displayName)
                    .font(.headline)
                    .foregroundStyle(.primary)

                if let timestamp = lastCheckedAt {
                    Text("Dernière vérification: \(timestamp)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(backgroundColor)
        .cornerRadius(8)
    }

    private var stateColor: Color {
        switch state {
        case .unknown:
            return .gray
        case .checking:
            return .blue
        case .healthy:
            return .green
        case .attention:
            return .orange
        case .error:
            return .red
        }
    }

    private var backgroundColor: Color {
        stateColor.opacity(0.1)
    }
}

// MARK: - Operation Status Badge

/// Displays an operation status (queued, running, succeeded, etc.)
struct OperationStatusBadge: View {
    let status: OperationStatus
    let displayName: String?

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: status.symbolName)
                .font(.system(size: 12, weight: .semibold))

            if let name = displayName {
                Text(name)
                    .font(.caption)
            }

            Text(status.displayName)
                .font(.caption)
                .fontWeight(.semibold)

            if status.isTerminal {
                // Terminal state - static
            } else {
                // Running state - show progress indicator
                ProgressView()
                    .scaleEffect(0.7, anchor: .center)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(statusColor.opacity(0.15))
        .cornerRadius(4)
        .foregroundStyle(statusColor)
    }

    private var statusColor: Color {
        switch status {
        case .queued:
            return .gray
        case .running:
            return .blue
        case .succeeded:
            return .green
        case .partiallySucceeded:
            return .orange
        case .failed:
            return .red
        case .cancelled:
            return .gray
        }
    }
}

// MARK: - Empty State View

/// Generic empty state placeholder.
struct EmptyStateView: View {
    let symbolName: String
    let title: String
    let description: String?
    let actionLabel: String?
    let action: (() -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: symbolName)
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                if let desc = description {
                    Text(desc)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }

            if let label = actionLabel, let callback = action {
                Button(action: callback) {
                    Label(label, systemImage: "plus.circle.fill")
                        .font(.callout)
                }
                .buttonStyle(.bordered)
            }

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - Loading State View

/// Generic loading state with progress indicator.
struct LoadingStateView: View {
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.2)

            Text(message)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}

// MARK: - Section Header

/// Styled section header with optional action.
struct SectionHeader: View {
    let title: String
    let subtitle: String?
    let actionLabel: String?
    let action: (() -> Void)?

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)

                if let sub = subtitle {
                    Text(sub)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if let label = actionLabel, let callback = action {
                Button(label, action: callback)
                    .font(.caption)
                    .buttonStyle(.bordered)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Inline Feedback View

/// Transient feedback message (success, warning, error).
struct InlineFeedbackView: View {
    enum FeedbackType {
        case success
        case warning
        case error
        case info

        var color: Color {
            switch self {
            case .success:
                return .green
            case .warning:
                return .orange
            case .error:
                return .red
            case .info:
                return .blue
            }
        }

        var symbolName: String {
            switch self {
            case .success:
                return "checkmark.circle.fill"
            case .warning:
                return "exclamationmark.circle.fill"
            case .error:
                return "xmark.circle.fill"
            case .info:
                return "info.circle.fill"
            }
        }
    }

    let type: FeedbackType
    let message: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: type.symbolName)
                .font(.system(size: 16))

            Text(message)
                .font(.callout)

            Spacer()
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(type.color.opacity(0.15))
        .cornerRadius(6)
        .foregroundStyle(type.color)
    }
}

// MARK: - Preview
// Previews disabled due to model dependencies
// Will be enabled in future iterations
