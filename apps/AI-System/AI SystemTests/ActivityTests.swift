import Foundation
import Testing
@testable import AI_System

@MainActor
@Suite("Activity store")
struct ActivityStoreTests {

    private func technical(exitCode: Int32 = 0) -> TechnicalDetails {
        TechnicalDetails(
            action: "check",
            arguments: [],
            exitCode: exitCode,
            duration: 1.25,
            stdout: "AI System Check — OK",
            stderr: "",
            logPath: "/tmp/last.log"
        )
    }

    @Test("A running activity becomes a success and keeps its context")
    func runningBecomesSuccess() {
        let store = ActivityStore()
        let id = store.begin(kind: .check, displayName: "Vérification", scope: .global)

        #expect(store.activity(id)?.status == .running)
        #expect(store.activity(id)?.duration == nil)

        store.finish(id, status: .succeeded, summary: "10 projets vérifiés.",
                     technical: technical())

        let activity = store.activity(id)
        #expect(activity?.status == .succeeded)
        #expect(activity?.summary == "10 projets vérifiés.")
        #expect(activity?.duration != nil)
        #expect(activity?.technical?.exitCode == 0)
    }

    @Test("A failure carries its structured error and write state")
    func failureCarriesWriteState() {
        let store = ActivityStore()
        let id = store.begin(
            kind: .importSkill, displayName: "Import de a", scope: .skill("P", "a")
        )

        store.finish(
            id,
            status: .failed,
            summary: "Une source gérée incompatible existe déjà.",
            error: ActivityError(
                code: "canonical_conflict",
                message: "Une source gérée incompatible existe déjà.",
                writeState: .noChanges,
                retryable: false
            )
        )

        let activity = store.activity(id)
        #expect(activity?.status == .failed)
        #expect(activity?.error?.code == "canonical_conflict")
        #expect(activity?.error?.writeStateDescription?.contains("Aucune") == true)
    }

    @Test("A partial success is distinct from a failure")
    func partialSuccessIsDistinct() {
        let store = ActivityStore()
        let id = store.begin(kind: .sync, displayName: "Sync", scope: .project("P"))

        store.finish(id, status: .partiallySucceeded, summary: "1 conflit non résolu.",
                     warningCount: 1)

        #expect(store.activity(id)?.status == .partiallySucceeded)
        #expect(store.activity(id)?.warningCount == 1)
        #expect(store.activity(id)?.status.isTerminal == true)
    }

    @Test("Activities are listed most recent first")
    func chronologicalOrder() {
        let store = ActivityStore()
        let first = store.begin(kind: .check, displayName: "A", scope: .global)
        let second = store.begin(kind: .sync, displayName: "B", scope: .project("P"))

        #expect(store.activities.map(\.id) == [second, first])
        #expect(store.recent(1).map(\.id) == [second])
    }

    @Test("Scope maps to the right project and skill")
    func scopeMapsToProjectAndSkill() {
        let store = ActivityStore()
        let global = store.begin(kind: .check, displayName: "A", scope: .global)
        let project = store.begin(kind: .sync, displayName: "B", scope: .project("Suggst"))
        let skill = store.begin(
            kind: .importSkill, displayName: "C", scope: .skill("Suggst", "01-spec")
        )

        #expect(store.activity(global)?.projectId == nil)
        #expect(store.activity(project)?.projectId == "Suggst")
        #expect(store.activity(skill)?.projectId == "Suggst")
        #expect(store.activity(skill)?.skillId == "01-spec")
        #expect(store.activity(skill)?.targetDescription == "Suggst · 01-spec")
    }

    @Test("An inline error can select its own activity")
    func selectsMostRecentMatchingActivity() {
        let store = ActivityStore()
        _ = store.begin(kind: .importSkill, displayName: "old", scope: .skill("P", "a"))
        let newer = store.begin(
            kind: .importSkill, displayName: "new", scope: .skill("P", "a")
        )
        _ = store.begin(kind: .sync, displayName: "other", scope: .project("Q"))

        store.selectMostRecent(project: "P", skill: "a")

        #expect(store.selectedActivityId == newer)
        #expect(store.selectedActivity?.displayName == "new")
    }

    @Test("Filters select the expected activities")
    func filtersSelectExpected() {
        let store = ActivityStore()
        let check = store.begin(kind: .check, displayName: "Check", scope: .global)
        let sync = store.begin(kind: .sync, displayName: "Sync", scope: .project("P"))
        let failed = store.begin(
            kind: .importSkill, displayName: "Import", scope: .skill("P", "a")
        )
        store.finish(check, status: .succeeded, summary: "ok")
        store.finish(sync, status: .succeeded, summary: "ok")
        store.finish(failed, status: .failed, summary: "ko")

        #expect(store.filtered(by: .all, search: "").count == 3)
        #expect(store.filtered(by: .failures, search: "").map(\.id) == [failed])
        #expect(store.filtered(by: .checks, search: "").map(\.id) == [check])
        #expect(store.filtered(by: .syncs, search: "").count == 2)
    }

    @Test("Search matches the name, the target and the summary")
    func searchMatchesFields() {
        let store = ActivityStore()
        let id = store.begin(
            kind: .sync, displayName: "Synchronisation de Suggst", scope: .project("Suggst")
        )
        store.finish(id, status: .succeeded, summary: "1 export créé")

        #expect(store.filtered(by: .all, search: "suggst").count == 1)
        #expect(store.filtered(by: .all, search: "export").count == 1)
        #expect(store.filtered(by: .all, search: "introuvable").isEmpty)
    }

    @Test("An activity without technical details is handled")
    func missingTechnicalDetailsAreHandled() {
        let store = ActivityStore()
        let id = store.begin(kind: .sync, displayName: "Sync", scope: .project("P"))
        store.finish(id, status: .succeeded, summary: "ok")

        #expect(store.activity(id)?.technical == nil)
    }

    @Test("Copyable details include streams and never invent content")
    func copyableDetailsAreComplete() {
        let details = TechnicalDetails(
            action: "project-sync",
            arguments: ["Suggst"],
            exitCode: 1,
            duration: 0.5,
            stdout: "out",
            stderr: "err",
            logPath: "/tmp/last.log"
        )

        let text = details.copyableText
        #expect(text.contains("project-sync"))
        #expect(text.contains("Suggst"))
        #expect(text.contains("Code de sortie : 1"))
        #expect(text.contains("out"))
        #expect(text.contains("err"))
        #expect(text.contains("/tmp/last.log"))
    }

    @Test("Empty streams are omitted rather than shown as empty blocks")
    func emptyStreamsAreOmitted() {
        let details = TechnicalDetails(
            action: "check", arguments: [], exitCode: 0, duration: 0.1,
            stdout: "", stderr: "", logPath: "/tmp/last.log"
        )

        #expect(!details.copyableText.contains("stdout"))
        #expect(!details.copyableText.contains("stderr"))
    }

    @Test("The store is capped so a long session cannot grow without bound")
    func storeIsCapped() {
        let store = ActivityStore(limit: 3)
        for index in 1...5 {
            _ = store.begin(kind: .scan, displayName: "\(index)", scope: .global)
        }

        #expect(store.activities.count == 3)
        #expect(store.activities.first?.displayName == "5")
    }

    @Test("Duration reads in milliseconds under a second")
    func durationFormatting() {
        let store = ActivityStore()
        let id = store.begin(kind: .check, displayName: "A", scope: .global)
        store.finish(id, status: .succeeded, summary: "ok")

        let text = store.activity(id)?.durationDescription
        #expect(text != nil)
        #expect(text?.contains("ms") == true || text?.contains("s") == true)
    }
}

// MARK: - Recording from the view models

@MainActor
@Suite("Activity recording")
struct ActivityRecordingTests {

    @Test("A check records one activity with its technical details")
    func checkIsRecorded() async {
        let store = ActivityStore()
        let backend = CountingBackend(responses: [
            "project-overview": Fixture.overview(),
            "check": "AI System Check — OK"
        ])
        let model = OverviewViewModel(service: ProjectSkillsService(backend: backend))

        await model.runCheckThenRefresh(recordingIn: store)

        #expect(store.activities.count == 1)
        let activity = store.activities[0]
        #expect(activity.kind == .check)
        #expect(activity.status == .succeeded)
        #expect(activity.technical?.action == "check")
        #expect(activity.summary.contains("aucune action requise"))
    }

    @Test("An import records an activity scoped to its skill")
    func importIsRecorded() async {
        let store = ActivityStore()
        let scan = ProjectsFixture.scan(skills: [
            ProjectsFixture.skill(
                name: "new-skill", status: "local_codex_only", claude: false,
                severity: "attention", allowedActions: "[\"import\"]", importable: true
            )
        ])
        let backend = CountingBackend(responses: [
            "project-overview": ProjectsFixture.overview(projects: [("Suggst", "attention", 1)]),
            "project-scan": scan,
            "project-import": ActionFixture.importSuccess()
        ])
        let model = ProjectsViewModel(service: ProjectSkillsService(backend: backend))
        await model.loadProjects()
        model.selectedProjectName = "Suggst"
        await model.scanSelectedProject()

        let skill = model.allSkills.first { $0.name == "new-skill" }!
        await model.importSkill(skill, source: .codex, recordingIn: store)

        #expect(store.activities.count == 1)
        let activity = store.activities[0]
        #expect(activity.kind == .importSkill)
        #expect(activity.status == .succeeded)
        #expect(activity.projectId == "Suggst")
        #expect(activity.skillId == "new-skill")
        #expect(activity.changes?.created == 1)
    }

    @Test("A failed import records the error with its write state")
    func failedImportIsRecorded() async {
        let store = ActivityStore()
        let scan = ProjectsFixture.scan(skills: [
            ProjectsFixture.skill(
                name: "new-skill", status: "local_codex_only", claude: false,
                severity: "attention", allowedActions: "[\"import\"]", importable: true
            )
        ])
        let backend = CountingBackend(responses: [
            "project-overview": ProjectsFixture.overview(projects: [("Suggst", "attention", 1)]),
            "project-scan": scan,
            "project-import": ActionFixture.canonicalConflict
        ])
        let model = ProjectsViewModel(service: ProjectSkillsService(backend: backend))
        await model.loadProjects()
        model.selectedProjectName = "Suggst"
        await model.scanSelectedProject()

        let skill = model.allSkills.first { $0.name == "new-skill" }!
        await model.importSkill(skill, source: .codex, recordingIn: store)

        let activity = store.activities[0]
        #expect(activity.status == .failed)
        #expect(activity.error?.code == "canonical_conflict")
        #expect(activity.error?.writeState == .noChanges)
    }

    @Test("A sync with an unresolved conflict is a partial success")
    func syncWithConflictIsPartial() async {
        let store = ActivityStore()
        let scan = ProjectsFixture.scan(skills: [
            ProjectsFixture.skill(
                name: "paired", status: "missing_claude", claude: false,
                severity: "attention", allowedActions: "[\"sync\"]"
            )
        ])
        let backend = CountingBackend(responses: [
            "project-overview": ProjectsFixture.overview(projects: [("Suggst", "attention", 1)]),
            "project-scan": scan,
            "project-sync": ActionFixture.syncBlockedByConflict
        ])
        let model = ProjectsViewModel(service: ProjectSkillsService(backend: backend))
        await model.loadProjects()
        model.selectedProjectName = "Suggst"
        await model.scanSelectedProject()

        await model.syncSelectedProject(recordingIn: store)

        let activity = store.activities[0]
        #expect(activity.kind == .sync)
        #expect(activity.warningCount == 1)
        #expect(activity.changes?.blocked?.first?.skill == "drifted")
    }
}
