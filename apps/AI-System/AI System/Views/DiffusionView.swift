import SwiftUI

struct DiffusionView: View {
    @Environment(CommandCenter.self) private var center

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Diffusion")
                .font(.largeTitle.bold())

            RunStatusView(currentRun: center.currentRun, lastResult: center.lastResult)

            VStack(alignment: .leading, spacing: 8) {
                PrimaryActionButton(
                    title: "Tout diffuser",
                    systemImage: "arrow.triangle.2.circlepath",
                    disabled: center.isRunning
                ) {
                    await center.execute(.update)
                }

                PrimaryActionButton(
                    title: "Codex seulement",
                    systemImage: "shippingbox",
                    disabled: center.isRunning
                ) {
                    await center.execute(.updateCodex)
                }

                PrimaryActionButton(
                    title: "Claude seulement",
                    systemImage: "brain",
                    disabled: center.isRunning
                ) {
                    await center.execute(.updateClaude)
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
