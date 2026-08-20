import SwiftUI

struct ResultPanel: View {
    let result: CommandResult

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text("Exit code: \(result.exitCode)")
                        .font(.caption.bold())
                        .foregroundStyle(result.succeeded ? .green : .red)
                    Text(String(format: "%.1fs", result.duration))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if !result.stdout.isEmpty {
                    Text(result.stdout)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                }

                if !result.stderr.isEmpty {
                    Text(result.stderr)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.red)
                        .textSelection(.enabled)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(8)
        }
        .background(.quaternary.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .frame(maxHeight: 240)
    }
}
