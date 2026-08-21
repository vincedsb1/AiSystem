import SwiftUI

/// Signature visualisation of the managed flow: AI System → projects →
/// Claude/Codex. Connectors are deliberately simple and decorative; meaning
/// is carried by the text nodes and their actions.
struct SystemPulseView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let model: SystemPulseModel
    let onOpenProjects: () -> Void
    let onOpenIssue: () -> Void

    @State private var flowHighlight = false

    var body: some View {
        SemanticSurface(tone: surfaceTone, cornerRadius: AppRadius.hero) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text("System Pulse")
                            .font(.headline)
                        Text("Le système qui maintient vos projets cohérents")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: Spacing.md)

                    Label(model.state.title, systemImage: model.state.symbolName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(model.state.tint)
                }

                ViewThatFits(in: .horizontal) {
                    horizontalLayout
                        .frame(minWidth: 650, alignment: .leading)
                    verticalLayout
                }
            }
            .padding(Spacing.lg)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(model.accessibilitySummary)
        .functionalAnimation(flowHighlight, reduceMotion: reduceMotion)
        .onChange(of: model.state) { oldState, newState in
            guard oldState == .checking, newState != .checking else { return }
            guard !reduceMotion else {
                flowHighlight = false
                return
            }
            flowHighlight = true
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(650))
                flowHighlight = false
            }
        }
    }

    private var horizontalLayout: some View {
        HStack(spacing: 0) {
            node(.core)
            connector
            node(.projects)
            connector
            VStack(spacing: Spacing.sm) {
                node(.claude)
                node(.codex)
            }
        }
    }

    private var verticalLayout: some View {
        VStack(spacing: 0) {
            node(.core)
            verticalConnector
            node(.projects)
            verticalConnector
            HStack(spacing: Spacing.sm) {
                node(.claude)
                node(.codex)
            }
        }
    }

    private func node(_ kind: SystemPulseNodeKind) -> some View {
        let node = model.nodes.first { $0.id == kind }!
        let action: (() -> Void)? = node.isInteractive
            ? (model.state == .attention || model.state == .error
                ? onOpenIssue
                : onOpenProjects)
            : nil

        return SystemPulseNode(node: node, action: action)
            .frame(maxWidth: .infinity)
    }

    private var connector: some View {
        SystemPulseConnector(
            state: model.state,
            highlighted: flowHighlight
        )
        .frame(width: 28)
    }

    private var verticalConnector: some View {
        SystemPulseConnector(
            state: model.state,
            highlighted: flowHighlight,
            vertical: true
        )
        .frame(height: 18)
    }

    private var surfaceTone: SemanticSurfaceTone {
        switch model.state {
        case .unknown, .checking: return .neutral
        case .healthy: return .success
        case .attention: return .attention
        case .error: return .error
        }
    }
}

private struct SystemPulseNode: View {
    let node: SystemPulseNodeModel
    let action: (() -> Void)?

    var body: some View {
        Group {
            if let action {
                Button(action: action) {
                    content
                }
                .buttonStyle(.plain)
                .help("Ouvrir le contexte de \(node.title)")
            } else {
                content
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(node.accessibilityLabel)
    }

    private var content: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: node.symbolName)
                .font(.title3.weight(.semibold))
                .foregroundStyle(node.state.tint)
                .frame(width: 28)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(node.title)
                    .font(.body.weight(.semibold))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(node.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.sm)
        .background(
            Color.primary.opacity(0.035),
            in: RoundedRectangle(cornerRadius: AppRadius.compact, style: .continuous)
        )
        .contentShape(RoundedRectangle(cornerRadius: AppRadius.compact, style: .continuous))
    }
}

private struct SystemPulseConnector: View {
    let state: SystemState
    let highlighted: Bool
    var vertical = false

    var body: some View {
        Capsule()
            .fill(state.tint.opacity(highlighted ? 0.95 : 0.38))
            .frame(width: vertical ? 2 : nil, height: vertical ? nil : 2)
            .overlay {
                if state == .unknown {
                    Capsule()
                        .stroke(style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                        .foregroundStyle(state.tint.opacity(0.72))
                }
            }
            .accessibilityHidden(true)
    }
}

#Preview("System Pulse — Healthy") {
    SystemPulseView(
        model: SystemPulseModel(overview: nil, state: .unknown, isRunning: false),
        onOpenProjects: {},
        onOpenIssue: {}
    )
    .padding()
    .frame(width: 760)
}
