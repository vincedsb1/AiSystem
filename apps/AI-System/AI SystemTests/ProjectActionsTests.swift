import Foundation
import Testing
@testable import AI_System

// MARK: - Fixtures

enum ActionFixture {

    static func importSuccess(skill: String = "new-skill") -> String {
        """
        {
          "schemaVersion":1,"status":"ok","generatedAt":"2026-08-20T17:34:57Z",
          "action":"import","project":"Suggst","skill":"\(skill)",
          "outcome":"imported","writeState":"applied",
          "summary":"\(skill) est désormais géré par AI System (suggst.\(skill)).",
          "changes":{"created":1,"updated":0,"unchanged":0,
            "canonicalId":"suggst.\(skill)","canonicalPath":"/tmp/canonical.md",
            "targets":["claude","codex"]},
          "error":null
        }
        """
    }

    static let alreadyManaged = """
    {
      "schemaVersion":1,"status":"ok","generatedAt":"2026-08-20T17:34:57Z",
      "action":"import","project":"Suggst","skill":"new-skill",
      "outcome":"already_managed","writeState":"no_changes",
      "summary":"new-skill est déjà géré par AI System.",
      "changes":{"created":0,"updated":0,"unchanged":1,
        "canonicalId":"suggst.new-skill"},
      "error":null
    }
    """

    static let canonicalConflict = """
    {
      "schemaVersion":1,"status":"error","generatedAt":"2026-08-20T17:34:57Z",
      "action":"import","project":"Suggst","skill":"new-skill",
      "outcome":"failed","writeState":"no_changes",
      "summary":"Une source gérée incompatible existe déjà.","changes":null,
      "error":{"code":"canonical_conflict",
        "message":"Une source gérée incompatible existe déjà.",
        "details":{},"retryable":false,"writeState":"no_changes",
        "suggestedAction":"review_conflict"}
    }
    """

    static let rolledBack = """
    {
      "schemaVersion":1,"status":"error","generatedAt":"2026-08-20T17:34:57Z",
      "action":"import","project":"Suggst","skill":"new-skill",
      "outcome":"failed","writeState":"rolled_back",
      "summary":"Le manifest n'a pas pu être écrit ; l'import a été annulé.",
      "changes":null,
      "error":{"code":"manifest_write_failed",
        "message":"Le manifest n'a pas pu être écrit ; l'import a été annulé.",
        "details":{},"retryable":true,"writeState":"rolled_back",
        "suggestedAction":null}
    }
    """

    static let syncCreated = """
    {
      "schemaVersion":1,"status":"ok","generatedAt":"2026-08-20T17:34:57Z",
      "action":"sync","project":"Suggst","skill":null,
      "outcome":"synced","writeState":"applied",
      "summary":"Synchronisation terminée — 1 export créé, 19 inchangés.",
      "changes":{"created":1,"updated":0,"unchanged":19,"conflicts":0,
        "failures":[],"targets":[],"blocked":[],"applied":true},
      "error":null
    }
    """

    static let syncUnchanged = """
    {
      "schemaVersion":1,"status":"ok","generatedAt":"2026-08-20T17:34:57Z",
      "action":"sync","project":"Suggst","skill":null,
      "outcome":"synced","writeState":"no_changes",
      "summary":"Synchronisation terminée — aucun changement.",
      "changes":{"created":0,"updated":0,"unchanged":20,"conflicts":0,
        "failures":[],"targets":[],"blocked":[],"applied":true},
      "error":null
    }
    """

    static let syncBlockedByConflict = """
    {
      "schemaVersion":1,"status":"ok","generatedAt":"2026-08-20T17:34:57Z",
      "action":"sync","project":"Suggst","skill":null,
      "outcome":"synced","writeState":"no_changes",
      "summary":"Synchronisation terminée — aucun changement — 1 conflit non résolu.",
      "changes":{"created":0,"updated":0,"unchanged":19,"conflicts":1,
        "failures":[],"targets":[],
        "blocked":[{"skill":"drifted","status":"conflict"}],"applied":true},
      "error":null
    }
    """
}

/// Backend double that counts calls, so a double submission is observable.
final class CountingBackend: BackendExecuting, @unchecked Sendable {
    private let lock = NSLock()
    private var _calls: [String] = []
    private let responses: [String: String]
    private let delay: Duration

    init(responses: [String: String], delay: Duration = .zero) {
        self.responses = responses
        self.delay = delay
    }

    var calls: [String] {
        lock.lock(); defer { lock.unlock() }
        return _calls
    }

    func callCount(for action: String) -> Int {
        calls.filter { $0 == action }.count
    }

    func run(action: String, args: [String]) async -> CommandResult {
        lock.lock(); _calls.append(action); lock.unlock()
        if delay > .zero { try? await Task.sleep(for: delay) }
        guard let stdout = responses[action] else {
            return CommandResult(stdout: "", stderr: "no stub", exitCode: 1, duration: 0)
        }
        return CommandResult(stdout: stdout, stderr: "", exitCode: 0, duration: 0.01)
    }
}

// MARK: - Decoding

@Suite("Action decoding")
struct ActionDecodingTests {

    @Test("Decodes a successful import")
    func decodesImport() throws {
        let result = BackendJSONDecoder.shared.decode(
            ProjectActionResponse.self,
            from: Data(ActionFixture.importSuccess().utf8)
        )
        let payload = try #require(try? result.get())

        #expect(payload.outcome == .imported)
        #expect(payload.writeState == .applied)
        #expect(payload.changes?.created == 1)
        #expect(payload.changes?.canonicalId == "suggst.new-skill")
        #expect(payload.succeeded)
    }

    @Test("Decodes an already-managed outcome as a success without changes")
    func decodesAlreadyManaged() throws {
        let payload = try #require(try? BackendJSONDecoder.shared.decode(
            ProjectActionResponse.self,
            from: Data(ActionFixture.alreadyManaged.utf8)
        ).get())

        #expect(payload.outcome == .alreadyManaged)
        #expect(payload.outcome.isSuccess)
        #expect(payload.writeState == .noChanges)
        #expect(payload.changes?.hasChanges == false)
    }

    @Test("Decodes blocked skills reported by a sync")
    func decodesBlockedSkills() throws {
        let payload = try #require(try? BackendJSONDecoder.shared.decode(
            ProjectActionResponse.self,
            from: Data(ActionFixture.syncBlockedByConflict.utf8)
        ).get())

        #expect(payload.changes?.conflicts == 1)
        #expect(payload.changes?.blocked?.first?.skill == "drifted")
        #expect(payload.changes?.blocked?.first?.status == .conflict)
    }

    @Test("Every write state carries a sentence about what changed on disk")
    func writeStatesDescribeDiskEffect() {
        #expect(ActionWriteState.noChanges.description.contains("Aucune"))
        #expect(ActionWriteState.rolledBack.description.contains("annulées"))
        #expect(ActionWriteState.partialChanges.description.contains("Certaines"))
        #expect(ActionWriteState.applied.description.contains("appliquées"))
    }
}

// MARK: - Import orchestration

@MainActor
@Suite("Import orchestration")
struct ImportOrchestrationTests {

    private func loadedModel(_ backend: CountingBackend) async -> ProjectsViewModel {
        let sut = ProjectsViewModel(service: ProjectSkillsService(backend: backend))
        await sut.loadProjects()
        sut.selectedProjectName = "Suggst"
        await sut.scanSelectedProject()
        return sut
    }

    private static func scan(withImportable: Bool) -> String {
        ProjectsFixture.scan(skills: [
            ProjectsFixture.skill(name: "synced", status: "managed_synced"),
            withImportable
                ? ProjectsFixture.skill(
                    name: "new-skill", status: "local_codex_only", claude: false,
                    severity: "attention", allowedActions: "[\"import\"]", importable: true
                  )
                : ProjectsFixture.skill(name: "new-skill", status: "managed_synced")
        ])
    }

    @Test("Import is only offered when the backend declares it allowed")
    func importOfferedOnlyWhenAllowed() async {
        let sut = await loadedModel(CountingBackend(responses: [
            "project-overview": ProjectsFixture.overview(projects: [("Suggst", "attention", 1)]),
            "project-scan": Self.scan(withImportable: true)
        ]))

        let importable = try? #require(sut.allSkills.first { $0.name == "new-skill" })
        let synced = try? #require(sut.allSkills.first { $0.name == "synced" })

        #expect(sut.canImport(importable!))
        #expect(!sut.canImport(synced!))
    }

    @Test("The source comes from the backend-reported presence")
    func sourceComesFromPresence() async {
        let sut = await loadedModel(CountingBackend(responses: [
            "project-overview": ProjectsFixture.overview(projects: [("Suggst", "attention", 1)]),
            "project-scan": Self.scan(withImportable: true)
        ]))

        let skill = sut.allSkills.first { $0.name == "new-skill" }!
        #expect(sut.importSource(for: skill) == .codex)
    }

    @Test("A successful import rescans so the row reaches its final state")
    func successfulImportRescans() async {
        let backend = CountingBackend(responses: [
            "project-overview": ProjectsFixture.overview(projects: [("Suggst", "attention", 1)]),
            "project-scan": Self.scan(withImportable: true),
            "project-import": ActionFixture.importSuccess()
        ])
        let sut = await loadedModel(backend)
        let scansBefore = backend.callCount(for: "project-scan")

        let skill = sut.allSkills.first { $0.name == "new-skill" }!
        await sut.importSkill(skill, source: .codex)

        #expect(backend.callCount(for: "project-import") == 1)
        #expect(backend.callCount(for: "project-scan") == scansBefore + 1)
        #expect(sut.operationState(for: skill) == .succeeded(
            "new-skill est désormais géré par AI System (suggst.new-skill)."
        ))
        #expect(sut.lastActionSucceeded)
    }

    @Test("A second submission while one import runs is refused")
    func doubleSubmissionIsRefused() async {
        let backend = CountingBackend(
            responses: [
                "project-overview": ProjectsFixture.overview(projects: [("Suggst", "attention", 1)]),
                "project-scan": Self.scan(withImportable: true),
                "project-import": ActionFixture.importSuccess()
            ],
            delay: .milliseconds(120)
        )
        let sut = await loadedModel(backend)
        let skill = sut.allSkills.first { $0.name == "new-skill" }!

        async let first: Void = sut.importSkill(skill, source: .codex)
        // Give the first call time to flip the row into `running`.
        try? await Task.sleep(for: .milliseconds(20))
        await sut.importSkill(skill, source: .codex)
        await first

        #expect(backend.callCount(for: "project-import") == 1)
    }

    @Test("A canonical conflict is reported and nothing is overwritten")
    func conflictIsReported() async {
        let backend = CountingBackend(responses: [
            "project-overview": ProjectsFixture.overview(projects: [("Suggst", "attention", 1)]),
            "project-scan": Self.scan(withImportable: true),
            "project-import": ActionFixture.canonicalConflict
        ])
        let sut = await loadedModel(backend)
        let skill = sut.allSkills.first { $0.name == "new-skill" }!

        await sut.importSkill(skill, source: .codex)

        guard case .failed(let message) = sut.operationState(for: skill) else {
            Issue.record("Expected a failed operation")
            return
        }
        #expect(message.contains("incompatible"))
        // The message states what happened on disk (spec 17.3).
        #expect(message.contains("Aucune modification"))
        #expect(!sut.lastActionSucceeded)
    }

    @Test("A rollback says so explicitly")
    func rollbackIsStated() async {
        let backend = CountingBackend(responses: [
            "project-overview": ProjectsFixture.overview(projects: [("Suggst", "attention", 1)]),
            "project-scan": Self.scan(withImportable: true),
            "project-import": ActionFixture.rolledBack
        ])
        let sut = await loadedModel(backend)
        let skill = sut.allSkills.first { $0.name == "new-skill" }!

        await sut.importSkill(skill, source: .codex)

        guard case .failed(let message) = sut.operationState(for: skill) else {
            Issue.record("Expected a failed operation")
            return
        }
        #expect(message.contains("annulées"))
    }

    @Test("A failure on one skill does not mark the others")
    func failureStaysOnItsRow() async {
        let backend = CountingBackend(responses: [
            "project-overview": ProjectsFixture.overview(projects: [("Suggst", "attention", 1)]),
            "project-scan": Self.scan(withImportable: true),
            "project-import": ActionFixture.canonicalConflict
        ])
        let sut = await loadedModel(backend)
        let skill = sut.allSkills.first { $0.name == "new-skill" }!
        let other = sut.allSkills.first { $0.name == "synced" }!

        await sut.importSkill(skill, source: .codex)

        #expect(sut.operationState(for: other) == .idle)
    }
}

// MARK: - Sync orchestration

@MainActor
@Suite("Sync orchestration")
struct SyncOrchestrationTests {

    private func loadedModel(
        _ backend: CountingBackend,
        state: String = "attention"
    ) async -> ProjectsViewModel {
        let sut = ProjectsViewModel(service: ProjectSkillsService(backend: backend))
        await sut.loadProjects()
        sut.selectedProjectName = "Suggst"
        await sut.scanSelectedProject()
        return sut
    }

    private static func syncableScan(conflicts: Int = 0) -> String {
        ProjectsFixture.scan(skills: [
            ProjectsFixture.skill(
                name: "paired", status: "missing_claude", claude: false,
                severity: "attention", allowedActions: "[\"sync\"]"
            )
        ]).replacingOccurrences(
            of: "\"conflicts\":0",
            with: "\"conflicts\":\(conflicts)"
        )
    }

    @Test("Sync is offered when the backend allows it and no conflict blocks it")
    func syncOfferedWhenAllowed() async {
        let sut = await loadedModel(CountingBackend(responses: [
            "project-overview": ProjectsFixture.overview(projects: [("Suggst", "attention", 1)]),
            "project-scan": Self.syncableScan()
        ]))

        #expect(sut.canSyncProject())
    }

    @Test("Sync is withheld while a conflict is unresolved")
    func syncWithheldOnConflict() async {
        let sut = await loadedModel(CountingBackend(responses: [
            "project-overview": ProjectsFixture.overview(projects: [("Suggst", "error", 1)]),
            "project-scan": Self.syncableScan(conflicts: 1)
        ]))

        #expect(!sut.canSyncProject())
    }

    @Test("A successful sync summarises the result and rescans")
    func successfulSyncSummarises() async {
        let backend = CountingBackend(responses: [
            "project-overview": ProjectsFixture.overview(projects: [("Suggst", "attention", 1)]),
            "project-scan": Self.syncableScan(),
            "project-sync": ActionFixture.syncCreated
        ])
        let sut = await loadedModel(backend)
        let scansBefore = backend.callCount(for: "project-scan")

        await sut.syncSelectedProject()

        #expect(backend.callCount(for: "project-sync") == 1)
        #expect(backend.callCount(for: "project-scan") == scansBefore + 1)
        #expect(sut.lastActionSucceeded)
        #expect(sut.lastActionSummary?.contains("1 export créé") == true)
    }

    @Test("A no-op sync says so without pretending anything changed")
    func noOpSyncIsHonest() async {
        let sut = await loadedModel(CountingBackend(responses: [
            "project-overview": ProjectsFixture.overview(projects: [("Suggst", "attention", 1)]),
            "project-scan": Self.syncableScan(),
            "project-sync": ActionFixture.syncUnchanged
        ]))

        await sut.syncSelectedProject()

        #expect(sut.lastActionSucceeded)
        #expect(sut.lastActionSummary?.contains("aucun changement") == true)
    }

    @Test("A running sync blocks a second submission")
    func syncBlocksSecondSubmission() async {
        let backend = CountingBackend(
            responses: [
                "project-overview": ProjectsFixture.overview(projects: [("Suggst", "attention", 1)]),
                "project-scan": Self.syncableScan(),
                "project-sync": ActionFixture.syncCreated
            ],
            delay: .milliseconds(120)
        )
        let sut = await loadedModel(backend)

        async let first: Void = sut.syncSelectedProject()
        try? await Task.sleep(for: .milliseconds(20))
        await sut.syncSelectedProject()
        await first

        #expect(backend.callCount(for: "project-sync") == 1)
    }
}
