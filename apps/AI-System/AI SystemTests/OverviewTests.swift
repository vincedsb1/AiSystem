import Foundation
import Testing
@testable import AI_System

// MARK: - Test double

/// Backend double returning canned payloads with controllable outcomes.
struct StubBackend: BackendExecuting {
    var stdout: String = ""
    var stderr: String = ""
    var exitCode: Int32 = 0
    var duration: TimeInterval = 0.01

    func run(action: String, args: [String]) async -> CommandResult {
        CommandResult(stdout: stdout, stderr: stderr, exitCode: exitCode, duration: duration)
    }
}

// MARK: - Fixtures

enum Fixture {
    static func overview(
        schemaVersion: Int = 1,
        state: String = "healthy",
        actionRequired: Int = 0,
        projectsHealthy: Int = 2,
        projectsAttention: Int = 0,
        projectsError: Int = 0,
        actions: String = "[]",
        projects: String? = nil
    ) -> String {
        let defaultProjects = """
        [
          {"name":"Alpha","root":"/tmp/Alpha","enabled":true,"state":"healthy",
           "summary":\(skillSummary()),"error":null},
          {"name":"Beta","root":"/tmp/Beta","enabled":true,"state":"healthy",
           "summary":\(skillSummary()),"error":null}
        ]
        """
        return """
        {
          "schemaVersion": \(schemaVersion),
          "status": "ok",
          "generatedAt": "2026-08-20T17:34:57Z",
          "state": "\(state)",
          "summary": {
            "projectsTotal": \(projectsHealthy + projectsAttention + projectsError),
            "projectsHealthy": \(projectsHealthy),
            "projectsAttention": \(projectsAttention),
            "projectsError": \(projectsError),
            "skillsTotal": 26,
            "skillsManaged": 20,
            "actionRequired": \(actionRequired),
            "expectedExceptions": 6,
            "conflicts": 0
          },
          "projects": \(projects ?? defaultProjects),
          "actions": \(actions),
          "error": null
        }
        """
    }

    static func skillSummary(actionRequired: Int = 0, conflicts: Int = 0) -> String {
        """
        {"total":26,"managed":20,"unmanaged":0,"shared":13,"projectSpecific":7,
         "missingClaude":0,"missingCodex":0,"drift":0,"conflicts":\(conflicts),
         "expectedExceptions":6,"actionRequired":\(actionRequired)}
        """
    }

    static let attentionAction = """
    [
      {"id":"Beta::new-skill","project":"Beta","skill":"new-skill",
       "canonicalId":null,"status":"local_codex_only","severity":"attention",
       "importable":true,"allowedActions":["import"]}
    ]
    """

    static let structuredError = """
    {
      "schemaVersion": 1,
      "status": "error",
      "generatedAt": "2026-08-20T17:34:57Z",
      "project": null,
      "summary": null,
      "skills": [],
      "error": {
        "code": "unknown_project",
        "message": "Project not found: Ghost",
        "details": {"project": "Ghost"}
      }
    }
    """
}

// MARK: - Decoding

@Suite("Overview decoding")
struct OverviewDecodingTests {

    @Test("Decodes a healthy overview payload")
    func decodesHealthyOverview() throws {
        let data = Data(Fixture.overview().utf8)
        let result = BackendJSONDecoder.shared.decode(SystemOverviewResponse.self, from: data)

        let payload = try #require(try? result.get())
        #expect(payload.schemaVersion == 1)
        #expect(payload.state == .healthy)
        #expect(payload.summary.projectsTotal == 2)
        #expect(payload.projects.count == 2)
        #expect(payload.actions.isEmpty)
        #expect(payload.observedAt != nil)
    }

    @Test("Decodes backend-authoritative severity and allowed actions")
    func decodesActionMetadata() throws {
        let data = Data(Fixture.overview(
            state: "attention",
            actionRequired: 1,
            projectsHealthy: 1,
            projectsAttention: 1,
            actions: Fixture.attentionAction
        ).utf8)

        let payload = try #require(
            try? BackendJSONDecoder.shared.decode(SystemOverviewResponse.self, from: data).get()
        )
        let action = try #require(payload.actions.first)

        #expect(action.severity == .attention)
        #expect(action.status == .localCodexOnly)
        #expect(action.allowedActions == ["import"])
        #expect(action.importable)
    }

    @Test("Rejects an unknown major schema version")
    func rejectsUnknownSchemaVersion() {
        let data = Data(Fixture.overview(schemaVersion: 99).utf8)
        let result = BackendJSONDecoder.shared.decode(SystemOverviewResponse.self, from: data)

        guard case .failure(let error) = result else {
            Issue.record("Expected a schema version failure")
            return
        }
        #expect(error == .schemaVersionMismatch(expected: 1, got: 99))
    }

    @Test("Tolerates additional fields")
    func toleratesAdditionalFields() {
        let payload = Fixture.overview().replacingOccurrences(
            of: "\"status\": \"ok\"",
            with: "\"status\": \"ok\", \"futureField\": {\"nested\": true}"
        )
        let result = BackendJSONDecoder.shared.decode(
            SystemOverviewResponse.self,
            from: Data(payload.utf8)
        )
        #expect((try? result.get()) != nil)
    }

    @Test("Extracts the JSON envelope from a wrapped stdout")
    func extractsEnvelopeFromWrappedOutput() {
        let stdout = """
        === AI System Action Log ===
        Timestamp: 2026-08-20 17:34:57
        ---
        \(Fixture.overview())
        """
        let data = ProjectSkillsService.jsonPayload(from: stdout)
        #expect(data != nil)
    }
}

// MARK: - Service

@Suite("Project skills service")
struct ProjectSkillsServiceTests {

    @Test("Surfaces a structured backend error rather than the exit code")
    func surfacesStructuredError() async {
        let service = ProjectSkillsService(
            backend: StubBackend(stdout: Fixture.structuredError, exitCode: 1)
        )

        let result = await service.scan(project: "Ghost")

        guard case .failure(let error) = result else {
            Issue.record("Expected a failure")
            return
        }
        #expect(error.code == "unknown_project")
        #expect(error.errorDescription == "Project not found: Ghost")
    }

    @Test("Reports a process failure when stdout carries no envelope")
    func reportsProcessFailure() async {
        let service = ProjectSkillsService(
            backend: StubBackend(stdout: "", stderr: "boom", exitCode: 2)
        )

        let result = await service.overview()

        guard case .failure(let error) = result else {
            Issue.record("Expected a failure")
            return
        }
        #expect(error == .processFailed(exitCode: 2, stderr: "boom"))
        #expect(error.isRetryable)
    }
}

// MARK: - View model

@MainActor
@Suite("Overview view model")
struct OverviewViewModelTests {

    private func model(_ backend: StubBackend) -> OverviewViewModel {
        OverviewViewModel(service: ProjectSkillsService(backend: backend))
    }

    @Test("Starts in the neutral unknown state, never an error")
    func startsUnknown() {
        let sut = model(StubBackend(stdout: Fixture.overview()))

        #expect(sut.displayState == .unknown)
        #expect(sut.errorMessage == nil)
        #expect(!sut.hasAttemptedLoad)
    }

    @Test("Loads a healthy snapshot and reports no action")
    func loadsHealthySnapshot() async {
        let sut = model(StubBackend(stdout: Fixture.overview()))

        await sut.load()

        #expect(sut.displayState == .healthy)
        #expect(sut.stateTitle == "Tout est synchronisé")
        #expect(sut.actions.isEmpty)
        #expect(sut.errorMessage == nil)
        #expect(sut.lastObservationText != nil)
    }

    @Test("Attention state carries the count in the title")
    func attentionTitleCarriesCount() async {
        let sut = model(StubBackend(stdout: Fixture.overview(
            state: "attention",
            actionRequired: 1,
            projectsHealthy: 1,
            projectsAttention: 1,
            actions: Fixture.attentionAction
        )))

        await sut.load()

        #expect(sut.displayState == .attention)
        #expect(sut.stateTitle == "1 élément demande votre attention")
        #expect(sut.topActions.count == 1)
        #expect(sut.remainingActionCount == 0)
    }

    @Test("Never lists more than five actions on the Overview")
    func capsActionList() async {
        let many = (1...8).map { index in
            """
            {"id":"P::skill\(index)","project":"P","skill":"skill\(index)",
             "canonicalId":null,"status":"local_codex_only","severity":"attention",
             "importable":true,"allowedActions":["import"]}
            """
        }.joined(separator: ",")

        let sut = model(StubBackend(stdout: Fixture.overview(
            state: "attention",
            actionRequired: 8,
            projectsHealthy: 0,
            projectsAttention: 1,
            actions: "[\(many)]"
        )))

        await sut.load()

        #expect(sut.actions.count == 8)
        #expect(sut.topActions.count == 5)
        #expect(sut.remainingActionCount == 3)
    }

    @Test("A failed refresh keeps the previous content and shows an inline error")
    func failedRefreshKeepsContent() async {
        let sut = model(StubBackend(stdout: Fixture.overview()))
        await sut.load()
        #expect(sut.displayState == .healthy)

        let failing = OverviewViewModel(
            service: ProjectSkillsService(backend: StubBackend(stderr: "down", exitCode: 1))
        )
        await failing.load()

        // The freshly failed model has no stale content to keep.
        #expect(failing.overview == nil)
        #expect(failing.displayState == .error)
        #expect(failing.errorMessage != nil)

        // The healthy model is untouched by the other model's failure
        // (no global lastResult propagation).
        #expect(sut.displayState == .healthy)
        #expect(sut.errorMessage == nil)
    }

    @Test("Errored projects are surfaced first for navigation")
    func errorProjectsSortFirst() async {
        let projects = """
        [
          {"name":"Zulu","root":"/tmp/Z","enabled":true,"state":"attention",
           "summary":\(Fixture.skillSummary(actionRequired: 1)),"error":null},
          {"name":"Alpha","root":"/tmp/A","enabled":true,"state":"error",
           "summary":\(Fixture.skillSummary(actionRequired: 1, conflicts: 1)),"error":null},
          {"name":"Mike","root":"/tmp/M","enabled":true,"state":"healthy",
           "summary":\(Fixture.skillSummary()),"error":null}
        ]
        """
        let sut = model(StubBackend(stdout: Fixture.overview(
            state: "error",
            actionRequired: 2,
            projectsHealthy: 1,
            projectsAttention: 1,
            projectsError: 1,
            projects: projects
        )))

        await sut.load()

        #expect(sut.projectsNeedingAttention.map(\.name) == ["Alpha", "Zulu"])
    }

    @Test("Unknown state stays neutral when nothing has been observed")
    func unknownStaysNeutral() async {
        let sut = model(StubBackend(stdout: Fixture.overview()))

        #expect(sut.displayState == .unknown)
        #expect(sut.summary == nil)
        // The description invites a check rather than reporting a failure.
        #expect(sut.stateDescription.contains("Analysez"))
    }
}
