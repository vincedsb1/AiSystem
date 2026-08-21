import Foundation
import Testing
@testable import AI_System

private enum UX3Fixture {
    static func overview(
        state: SystemState = .healthy,
        projectsTotal: Int = 10,
        projectsHealthy: Int = 10,
        actionRequired: Int = 0,
        skillsManaged: Int = 146
    ) -> SystemOverviewResponse {
        SystemOverviewResponse(
            schemaVersion: 1,
            status: "ok",
            generatedAt: "2026-08-20T17:34:57Z",
            state: state,
            summary: OverviewSummary(
                projectsTotal: projectsTotal,
                projectsHealthy: projectsHealthy,
                projectsAttention: actionRequired,
                projectsError: 0,
                skillsTotal: skillsManaged,
                skillsManaged: skillsManaged,
                actionRequired: actionRequired,
                expectedExceptions: 0,
                conflicts: 0
            ),
            projects: [],
            actions: [],
            error: nil
        )
    }

    static func project(_ name: String = "Suggst") -> OverviewProject {
        OverviewProject(
            name: name,
            root: "/tmp/\(name)",
            enabled: true,
            state: .healthy,
            summary: SkillSummary(
                total: 4,
                managed: 4,
                unmanaged: 0,
                shared: 4,
                projectSpecific: 0,
                missingClaude: 0,
                missingCodex: 0,
                drift: 0,
                conflicts: 0,
                expectedExceptions: 0,
                actionRequired: 0
            ),
            error: nil
        )
    }
}

@Suite("UX3 System Pulse")
struct SystemPulseTests {
    @Test("Maps healthy structured data into four useful nodes")
    func healthyNodes() {
        let model = SystemPulseModel(
            overview: UX3Fixture.overview(),
            state: .healthy,
            isRunning: false
        )

        #expect(model.nodes.count == 4)
        #expect(model.nodes.map(\.id) == [.core, .projects, .claude, .codex])
        #expect(model.nodes[0].subtitle == "146 skills gérés")
        #expect(model.nodes[1].title == "10 projets")
        #expect(model.accessibilitySummary.contains("Claude et Codex"))
    }

    @Test("Preserves neutral, attention and running states")
    func statesStayTruthful() {
        let unknown = SystemPulseModel(overview: nil, state: .unknown, isRunning: false)
        #expect(unknown.state == .unknown)
        #expect(unknown.nodes[1].subtitle == "État non vérifié")

        let attention = SystemPulseModel(
            overview: UX3Fixture.overview(
                state: .attention,
                projectsHealthy: 8,
                actionRequired: 2
            ),
            state: .attention,
            isRunning: false
        )
        #expect(attention.state == .attention)
        #expect(attention.nodes[1].subtitle == "2 à examiner")

        let running = SystemPulseModel(
            overview: UX3Fixture.overview(),
            state: .healthy,
            isRunning: true
        )
        #expect(running.state == .checking)
        #expect(running.nodes[2].subtitle == "Vérification en cours…")
    }
}

@Suite("UX3 Quick Command")
struct QuickCommandTests {
    @Test("Ranks exact, prefix and alias searches locally")
    func localSearch() {
        let context = QuickCommandContext(
            activeSection: .overview,
            selectedProjectName: nil,
            projects: [UX3Fixture.project()],
            skills: [],
            activities: [],
            operationIsRunning: false
        )
        let items = QuickCommandRegistry.items(context: context)

        let exact = QuickCommandSearchIndex.ranked(
            items,
            query: "Suggst",
            recentIDs: [],
            activeSection: .overview
        )
        #expect(exact.first?.intent == .openProject("Suggst"))

        let alias = QuickCommandSearchIndex.ranked(
            items,
            query: "health",
            recentIDs: [],
            activeSection: .overview
        )
        #expect(alias.first?.intent == .runCheck)

        let prefix = QuickCommandSearchIndex.ranked(
            items,
            query: "proj",
            recentIDs: [],
            activeSection: .overview
        )
        #expect(prefix.first?.intent == .navigate(.projects))
    }

    @Test("Keeps static commands available while data is unloaded")
    func staticCommandsDoNotWaitForData() {
        let context = QuickCommandContext(
            activeSection: .projects,
            selectedProjectName: nil,
            projects: [],
            skills: [],
            activities: [],
            operationIsRunning: false
        )
        let items = QuickCommandRegistry.items(context: context)

        #expect(items.contains { $0.id == "action:check" })
        #expect(items.contains { $0.id == "navigation:projects" })
        #expect(items.contains { $0.id == "resource:doctor" })
        #expect(items.first { $0.id == "action:sync:selected" }?.availability.isAvailable == false)
    }

    @Test("Blocks mutation intents while an operation is active")
    func mutationAvailability() {
        let context = QuickCommandContext(
            activeSection: .projects,
            selectedProjectName: "Suggst",
            projects: [UX3Fixture.project()],
            skills: [],
            activities: [],
            operationIsRunning: true
        )
        let items = QuickCommandRegistry.items(context: context)
        let check = items.first { $0.id == "action:check" }
        let sync = items.first { $0.id == "action:sync:Suggst" }

        #expect(check?.availability.isAvailable == false)
        #expect(sync?.availability.isAvailable == false)
    }

    @MainActor
    @Test("Recent commands are capped at five identifiers")
    func recentLimit() {
        let suiteName = "ai.system.ux3.quick-command.tests"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let store = QuickCommandRecentStore(defaults: defaults)

        for index in 1...6 {
            store.remember("item-\(index)")
        }

        #expect(store.ids.count == 5)
        #expect(store.ids.first == "item-6")
        #expect(!store.ids.contains("item-1"))
        defaults.removePersistentDomain(forName: suiteName)
    }
}

@MainActor
@Suite("UX3 Operation Experience")
struct OperationExperienceTests {
    @Test("CommandCenter exposes one running operation and a persistent failure")
    func commandCenterLifecycle() throws {
        let center = CommandCenter()
        let operationID = try #require(
            center.begin(
                kind: .sync,
                displayName: "Synchronisation",
                target: "Suggst"
            )
        )

        #expect(center.isRunning)
        #expect(center.currentOperation?.target == "Suggst")
        #expect(center.currentOperation?.headline == "Synchronisation…")

        center.finish(
            operationID: operationID,
            status: .failed,
            headline: "La synchronisation a échoué",
            statusMessage: "Aucun fichier n’a été modifié."
        )

        #expect(!center.isRunning)
        #expect(center.currentOperation?.state == .failed)
        #expect(center.currentOperation?.statusMessage?.contains("Aucun") == true)

        center.dismiss(operationID: operationID)
        #expect(center.currentOperation == nil)
    }

    @Test("Successful operations auto-dismiss after the short receipt window")
    func successAutoDismisses() async throws {
        let center = CommandCenter()
        let operationID = try #require(
            center.begin(
                kind: .check,
                displayName: "Vérification",
                target: "Système"
            )
        )

        center.finish(
            operationID: operationID,
            status: .succeeded,
            headline: "Tout est à jour"
        )
        #expect(center.currentOperation?.state == .succeeded)

        try await Task.sleep(for: .seconds(3.2))
        #expect(center.currentOperation == nil)
    }

    @Test("ActivityStore creates a semantic receipt from structured fields")
    func receiptIsStructured() throws {
        let store = ActivityStore()
        let id = store.begin(
            kind: .importSkill,
            displayName: "Import de new-skill",
            scope: .skill("Suggst", "new-skill")
        )
        store.finish(
            id,
            status: .succeeded,
            summary: "Source créée et exports synchronisés.",
            changes: ActionChanges(
                created: 1,
                updated: 1,
                unchanged: 2,
                conflicts: nil,
                canonicalId: "new-skill",
                canonicalPath: nil,
                targets: ["claude", "codex"],
                applied: true,
                blocked: nil
            ),
            technical: TechnicalDetails(
                action: "project-import",
                arguments: ["Suggst", "new-skill", "codex"],
                exitCode: 0,
                duration: 0.4,
                stdout: "human output is not used",
                stderr: "",
                logPath: "/tmp/last.log"
            )
        )

        let receipt = try #require(store.activity(id)?.receipt)
        #expect(receipt.headline == "new-skill est maintenant géré")
        #expect(receipt.createdCount == 1)
        #expect(receipt.updatedCount == 1)
        #expect(receipt.resources.map(\.id) == ["inventory", "doctor", "log"])
        #expect(receipt.technicalReference == "/tmp/last.log")
        #expect(!receipt.summary.contains("human output"))
    }

    @Test("Receipt headlines preserve terminal semantic states")
    func receiptStatusesStaySemantic() {
        let startedAt = Date(timeIntervalSince1970: 1)
        let finishedAt = Date(timeIntervalSince1970: 2)
        let activity = Activity(
            kind: .sync,
            displayName: "Synchronisation de Suggst",
            scope: .project("Suggst"),
            status: .partiallySucceeded,
            startedAt: startedAt,
            finishedAt: finishedAt,
            summary: "Un avertissement est à examiner."
        )

        #expect(OperationReceiptBuilder.headline(for: activity) == "Synchronisation de Suggst terminé avec avertissements")
    }
}
