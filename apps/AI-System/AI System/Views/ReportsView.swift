import SwiftUI

struct ReportsView: View {
    @Environment(CommandCenter.self) private var center

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Rapports")
                .font(.largeTitle.bold())

            RunStatusView(currentRun: center.currentRun, lastResult: center.lastResult)

            HStack(spacing: 12) {
                PrimaryActionButton(
                    title: "Ouvrir Inventory",
                    systemImage: "doc.text.magnifyingglass",
                    disabled: center.isRunning
                ) {
                    await center.execute(.openInventory)
                }

                PrimaryActionButton(
                    title: "Ouvrir Doctor",
                    systemImage: "stethoscope",
                    disabled: center.isRunning
                ) {
                    await center.execute(.openDoctor)
                }
            }

            if let result = center.lastResult, !result.succeeded {
                Text("Erreur")
                    .font(.headline)
                ResultPanel(result: result)
            }

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
