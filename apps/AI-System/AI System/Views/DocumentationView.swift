import SwiftUI

struct DocumentationView: View {
    @Environment(CommandCenter.self) private var center

    private let docs: [BackendAction] = [
        .openReadme,
        .openOperations,
        .openSkillWorkflow,
        .openProjectOnboarding,
        .openLocalGuiDesign,
        .openPlan
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Documentation")
                .font(.largeTitle.bold())

            VStack(alignment: .leading, spacing: 8) {
                ForEach(docs) { doc in
                    PrimaryActionButton(
                        title: doc.displayName,
                        systemImage: "doc.text",
                        disabled: center.isRunning
                    ) {
                        await center.execute(doc)
                    }
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
