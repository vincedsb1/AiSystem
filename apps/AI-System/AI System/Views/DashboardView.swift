import SwiftUI

struct DashboardView: View {
    @Environment(CommandCenter.self) private var center
    @Binding var selection: SidebarSection

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tableau de bord")
                .font(.largeTitle.bold())

            RunStatusView(currentRun: center.currentRun, lastResult: center.lastResult)

            HStack(spacing: 12) {
                PrimaryActionButton(
                    title: "Vérifier le système",
                    systemImage: "checkmark.shield",
                    disabled: center.isRunning
                ) {
                    await center.execute(.check)
                }

                PrimaryActionButton(
                    title: "Diffuser partout",
                    systemImage: "arrow.triangle.2.circlepath",
                    disabled: center.isRunning
                ) {
                    await center.execute(.update)
                }

                Button("Voir les logs") {
                    selection = .logs
                }
                .buttonStyle(.bordered)
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
