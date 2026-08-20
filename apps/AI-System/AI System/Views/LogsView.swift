import SwiftUI
import AppKit

struct LogsView: View {
    @Environment(CommandCenter.self) private var center

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Logs")
                .font(.largeTitle.bold())

            RunStatusView(currentRun: center.currentRun, lastResult: center.lastResult)

            HStack(spacing: 12) {
                Button("Copier les logs") {
                    copyLogs()
                }
                .disabled(center.lastResult == nil)

                Button("Effacer l'affichage") {
                    center.lastResult = nil
                }
                .disabled(center.lastResult == nil)

                Button("Ouvrir le dernier fichier log") {
                    openLogFile()
                }
            }

            if let result = center.lastResult {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Text("Exit code: \(result.exitCode)")
                                .font(.caption.bold())
                                .foregroundStyle(result.succeeded ? .green : .red)
                            Text(String(format: "%.1fs", result.duration))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        if !result.stdout.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("stdout")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(result.stdout)
                                    .font(.system(.caption, design: .monospaced))
                                    .textSelection(.enabled)
                            }
                        }

                        if !result.stderr.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("stderr")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(result.stderr)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundStyle(.red)
                                    .textSelection(.enabled)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                Text("Aucune action exécutée pour le moment.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func copyLogs() {
        guard let result = center.lastResult else { return }
        let text = """
        Exit code: \(result.exitCode)
        Duration: \(result.duration)s
        --- stdout ---
        \(result.stdout)
        --- stderr ---
        \(result.stderr)
        """
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    private func openLogFile() {
        NSWorkspace.shared.open(URL(fileURLWithPath: AISystemPaths.lastLog))
    }
}
