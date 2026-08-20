import SwiftUI

// MARK: - Operation status badge

/// Compact operation status. Colour is always paired with a symbol and a
/// label (FR-STATE-03).
struct OperationStatusBadge: View {
    let status: OperationStatus
    var displayName: String?

    var body: some View {
        HStack(spacing: Spacing.micro) {
            if status.isTerminal {
                Image(systemName: status.symbolName)
                    .font(.caption)
            } else {
                ProgressView().controlSize(.small)
            }

            if let displayName {
                Text(displayName)
                    .font(.caption)
            }

            Text(status.displayName)
                .font(.caption)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, Spacing.related)
        .padding(.vertical, Spacing.micro)
        .background(status.tint.opacity(0.15), in: Capsule())
        .foregroundStyle(status.tint)
        .accessibilityElement(children: .combine)
        .accessibilityLabel([displayName, status.displayName].compactMap { $0 }.joined(separator: ", "))
    }
}

// MARK: - Empty state

struct EmptyStateView: View {
    let symbolName: String
    let title: String
    var description: String?
    var actionLabel: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: Spacing.grouped) {
            Image(systemName: symbolName)
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            Text(title)
                .font(.headline)

            if let description {
                Text(description)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let actionLabel, let action {
                Button(actionLabel, action: action)
                    .buttonStyle(.borderedProminent)
                    .padding(.top, Spacing.micro)
            }
        }
        .padding(Spacing.major)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Loading state

struct LoadingStateView: View {
    let message: String

    var body: some View {
        VStack(spacing: Spacing.grouped) {
            ProgressView()
            Text(message)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message)
    }
}

// MARK: - Section header

struct SectionHeader: View {
    let title: String
    var subtitle: String?
    var actionLabel: String?
    var action: (() -> Void)?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if let actionLabel, let action {
                Button(actionLabel, action: action)
                    .controlSize(.small)
            }
        }
        .padding(.horizontal, Spacing.standard)
        .padding(.bottom, Spacing.related)
    }
}

// MARK: - Inline feedback

/// Contextual feedback. Success is never announced through a modal alert
/// (spec 17.1).
struct InlineFeedbackView: View {
    enum FeedbackType {
        case success
        case warning
        case error
        case info

        var tint: Color {
            switch self {
            case .success: return .green
            case .warning: return .orange
            case .error: return .red
            case .info: return .accentColor
            }
        }

        var symbolName: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .error: return "xmark.octagon.fill"
            case .info: return "info.circle.fill"
            }
        }

        var accessibilityPrefix: String {
            switch self {
            case .success: return "Succès"
            case .warning: return "Avertissement"
            case .error: return "Erreur"
            case .info: return "Information"
            }
        }
    }

    let type: FeedbackType
    let message: String
    var actionLabel: String?
    var action: (() -> Void)?

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.related) {
            Image(systemName: type.symbolName)
                .foregroundStyle(type.tint)
                .accessibilityHidden(true)

            Text(message)
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: Spacing.related)

            if let actionLabel, let action {
                Button(actionLabel, action: action)
                    .controlSize(.small)
            }
        }
        .padding(Spacing.grouped)
        .background(type.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(type.accessibilityPrefix). \(message)")
    }
}
