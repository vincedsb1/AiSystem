import SwiftUI

struct RunStatusView: View {
    let currentRun: RunState
    let lastResult: CommandResult?

    var body: some View {
        switch currentRun {
        case .idle:
            if let lastResult {
                StatusBadge(
                    label: lastResult.succeeded ? "Succès" : "Échec",
                    color: lastResult.succeeded ? .green : .red
                )
            } else {
                StatusBadge(label: "Idle", color: .secondary)
            }
        case .running(let action):
            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                Text(action)
                    .font(.caption)
            }
        }
    }
}
