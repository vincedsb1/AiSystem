import SwiftUI

struct ToolsView: View {
    @Environment(CommandCenter.self) private var center

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Outils")
                .font(.largeTitle.bold())

            RunStatusView(currentRun: center.currentRun, lastResult: center.lastResult)

            VStack(alignment: .leading, spacing: 8) {
                PrimaryActionButton(
                    title: "Installer le hook pre-commit",
                    systemImage: "link",
                    disabled: center.isRunning
                ) {
                    await center.execute(.installHooks)
                }

                PrimaryActionButton(
                    title: "Afficher l'état Git",
                    systemImage: "arrow.triangle.branch",
                    disabled: center.isRunning
                ) {
                    await center.execute(.gitStatus)
                }

                PrimaryActionButton(
                    title: "Ouvrir dans Cursor",
                    systemImage: "cursorarrow.rays",
                    disabled: center.isRunning
                ) {
                    await center.execute(.openCursor)
                }

                PrimaryActionButton(
                    title: "Ouvrir dans Terminal",
                    systemImage: "terminal",
                    disabled: center.isRunning
                ) {
                    await center.execute(.openTerminal)
                }

                PrimaryActionButton(
                    title: "Ouvrir dans Finder",
                    systemImage: "folder",
                    disabled: center.isRunning
                ) {
                    await center.execute(.openFinder)
                }
            }

            if let result = center.lastResult {
                Text("Dernier résultat")
                    .font(.headline)
                ResultPanel(result: result)
            }

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
