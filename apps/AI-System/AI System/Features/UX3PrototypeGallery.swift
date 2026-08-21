import SwiftUI

/// Isolated decision surface for UX3-00. It is preview-only and is not part of
/// the application's navigation or business workflow.
struct UX3PrototypeGallery: View {
    @State private var activityStore = ActivityStore()
    @State private var dataStore = AppDataStore()
    @State private var commandCenter = CommandCenter()

    private let healthyPulse = SystemPulseModel(
        overview: Self.fixtureOverview,
        state: .healthy,
        isRunning: false
    )

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                Text("UX3 prototypes")
                    .font(.title2.weight(.semibold))

                SystemPulseView(
                    model: healthyPulse,
                    onOpenProjects: {},
                    onOpenIssue: {}
                )

                QuickCommandView(
                    activityStore: activityStore,
                    dataStore: dataStore,
                    commandCenter: commandCenter,
                    onIntent: { _ in },
                    onDismiss: {}
                )

                OperationStatusControl(commandCenter: commandCenter, onOpenActivity: { _ in })
                    .padding(Spacing.md)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: AppRadius.section))
            }
            .padding(Spacing.lg)
        }
        .environment(activityStore)
        .environment(dataStore)
        .environment(commandCenter)
        .task {
            guard commandCenter.currentOperation == nil else { return }
            _ = commandCenter.begin(
                kind: .check,
                displayName: "Vérification du système",
                target: "Système"
            )
        }
    }

    private static let fixtureOverview = SystemOverviewResponse(
        schemaVersion: 1,
        status: "ok",
        generatedAt: "2026-08-20T17:34:57Z",
        state: .healthy,
        summary: OverviewSummary(
            projectsTotal: 10,
            projectsHealthy: 10,
            projectsAttention: 0,
            projectsError: 0,
            skillsTotal: 146,
            skillsManaged: 146,
            actionRequired: 0,
            expectedExceptions: 0,
            conflicts: 0
        ),
        projects: [],
        actions: [],
        error: nil
    )
}

#Preview("UX3 decision prototypes") {
    UX3PrototypeGallery()
        .frame(width: 900, height: 900)
}
