import Foundation
import Testing
@testable import AI_System

// MARK: - Fixtures

enum ProjectsFixture {

    static func skill(
        name: String,
        status: String,
        scope: String? = "project",
        canonicalId: String? = nil,
        claude: Bool = true,
        codex: Bool = true,
        severity: String? = nil,
        allowedActions: String = "[]",
        importable: Bool = false
    ) -> String {
        let canonical = canonicalId.map { "\"\($0)\"" } ?? "null"
        let scopeValue = scope.map { "\"\($0)\"" } ?? "null"
        let severityValue = severity.map { "\"\($0)\"" } ?? "null"
        return """
        {
          "name":"\(name)","canonicalId":\(canonical),
          "candidateCanonicalId":\(canonical),"scope":\(scopeValue),
          "sourceOfTruth":null,"description":null,
          "managed":\(status == "managed_synced"),"importable":\(importable),
          "presence":{"codex":\(codex),"claude":\(claude)},
          "paths":{"codex":null,"claude":null,"canonical":null},
          "status":"\(status)","severity":\(severityValue),
          "allowedActions":\(allowedActions),
          "exception":null,"conflict":null
        }
        """
    }

    static func scan(
        project: String = "Suggst",
        sharedTargets: [String] = ["claude", "codex"],
        skills: [String]
    ) -> String {
        let targets = sharedTargets.map { "\"\($0)\"" }.joined(separator: ",")
        return """
        {
          "schemaVersion":1,"status":"ok","generatedAt":"2026-08-20T17:34:57Z",
          "project":{"name":"\(project)","root":"/tmp/\(project)","enabled":true,
            "paths":{"codexSkills":"/tmp/\(project)/.agents/skills",
                     "claudeCommands":"/tmp/\(project)/.claude/commands"},
            "sharedTargets":[\(targets)]},
          "summary":{"total":\(skills.count),"managed":\(skills.count),"unmanaged":0,
            "shared":1,"projectSpecific":\(max(0, skills.count - 1)),
            "missingClaude":0,"missingCodex":0,"drift":0,"conflicts":0,
            "expectedExceptions":0,"actionRequired":0},
          "skills":[\(skills.joined(separator: ","))],
          "error":null
        }
        """
    }

    static func overview(projects: [(name: String, state: String, actions: Int)]) -> String {
        let entries = projects.map { project in
            """
            {"name":"\(project.name)","root":"/tmp/\(project.name)","enabled":true,
             "state":"\(project.state)",
             "summary":{"total":10,"managed":9,"unmanaged":0,"shared":3,
               "projectSpecific":7,"missingClaude":0,"missingCodex":0,"drift":0,
               "conflicts":0,"expectedExceptions":1,
               "actionRequired":\(project.actions)},
             "error":null}
            """
        }.joined(separator: ",")

        return """
        {
          "schemaVersion":1,"status":"ok","generatedAt":"2026-08-20T17:34:57Z",
          "state":"healthy",
          "summary":{"projectsTotal":\(projects.count),"projectsHealthy":\(projects.count),
            "projectsAttention":0,"projectsError":0,"skillsTotal":10,"skillsManaged":9,
            "actionRequired":0,"expectedExceptions":1,"conflicts":0},
          "projects":[\(entries)],"actions":[],"error":null
        }
        """
    }
}

/// Backend double that answers differently per route.
struct RoutingBackend: BackendExecuting {
    var responses: [String: String] = [:]
    var failingRoutes: Set<String> = []

    func run(action: String, args: [String]) async -> CommandResult {
        if failingRoutes.contains(action) {
            return CommandResult(stdout: "", stderr: "route down", exitCode: 1, duration: 0)
        }
        return CommandResult(
            stdout: responses[action] ?? "",
            stderr: "",
            exitCode: responses[action] == nil ? 1 : 0,
            duration: 0.01
        )
    }
}

// MARK: - Project list

@MainActor
@Suite("Projects list")
struct ProjectsListTests {

    private func model(_ backend: RoutingBackend) -> ProjectsViewModel {
        ProjectsViewModel(service: ProjectSkillsService(backend: backend))
    }

    @Test("Sorts errors first, then attention, then alphabetically")
    func sortsBySeverityThenName() async {
        let sut = model(RoutingBackend(responses: [
            "project-overview": ProjectsFixture.overview(projects: [
                ("Zulu", "healthy", 0),
                ("Mike", "attention", 2),
                ("Alpha", "healthy", 0),
                ("Bravo", "error", 1)
            ])
        ]))

        await sut.loadProjects()

        #expect(sut.sortedProjects.map(\.name) == ["Bravo", "Mike", "Alpha", "Zulu"])
    }

    @Test("Shows an empty state when no project is active")
    func reportsEmptyList() async {
        let sut = model(RoutingBackend(responses: [
            "project-overview": ProjectsFixture.overview(projects: [])
        ]))

        await sut.loadProjects()

        #expect(sut.isEmpty)
        #expect(sut.projectsError == nil)
    }

    @Test("Keeps the selection across a refresh when the project still exists")
    func keepsSelectionOnRefresh() async {
        let payload = ProjectsFixture.overview(projects: [
            ("Alpha", "healthy", 0), ("Beta", "healthy", 0)
        ])
        let sut = model(RoutingBackend(responses: ["project-overview": payload]))

        await sut.loadProjects()
        sut.selectedProjectName = "Beta"
        await sut.loadProjects()

        #expect(sut.selectedProjectName == "Beta")
    }

    @Test("Drops the selection when the project disappeared between two loads")
    func dropsSelectionWhenProjectDisappears() async {
        var backend = RoutingBackend(responses: [
            "project-overview": ProjectsFixture.overview(projects: [
                ("Alpha", "healthy", 0), ("Beta", "healthy", 0)
            ])
        ])
        let sut = model(backend)

        await sut.loadProjects()
        sut.selectedProjectName = "Beta"

        backend.responses["project-overview"] = ProjectsFixture.overview(projects: [
            ("Alpha", "healthy", 0)
        ])
        let refreshed = ProjectsViewModel(service: ProjectSkillsService(backend: backend))
        refreshed.selectedProjectName = "Beta"
        await refreshed.loadProjects()

        #expect(refreshed.selectedProjectName == nil)
    }

    @Test("A failed list refresh keeps the previous projects")
    func failedRefreshKeepsProjects() async {
        let sut = model(RoutingBackend(responses: [
            "project-overview": ProjectsFixture.overview(projects: [("Alpha", "healthy", 0)])
        ]))
        await sut.loadProjects()
        #expect(sut.projects.count == 1)

        let failing = model(RoutingBackend(failingRoutes: ["project-overview"]))
        await failing.loadProjects()

        #expect(failing.projects.isEmpty)
        #expect(failing.projectsError != nil)
        // The other model is untouched.
        #expect(sut.projects.count == 1)
        #expect(sut.projectsError == nil)
    }
}

// MARK: - Project detail

@MainActor
@Suite("Project detail")
struct ProjectDetailTests {

    private func loadedModel(
        scan: String,
        projects: [(name: String, state: String, actions: Int)] = [("Suggst", "healthy", 0)]
    ) async -> ProjectsViewModel {
        let backend = RoutingBackend(responses: [
            "project-overview": ProjectsFixture.overview(projects: projects),
            "project-scan": scan
        ])
        let sut = ProjectsViewModel(service: ProjectSkillsService(backend: backend))
        await sut.loadProjects()
        sut.selectedProjectName = projects.first?.name
        await sut.scanSelectedProject()
        return sut
    }

    @Test("Suggst exposes its seven project-scoped skills")
    func exposesProjectScopedSkills() async {
        let names = ["01-spec", "02-check", "03-split", "04-build", "05-finish", "06-pivot", "suggst-task"]
        let sut = await loadedModel(scan: ProjectsFixture.scan(
            skills: names.map {
                ProjectsFixture.skill(name: $0, status: "managed_synced", canonicalId: "suggst.\($0)")
            }
        ))

        #expect(sut.allSkills.count == 7)
        #expect(sut.allSkills.allSatisfy { $0.scope == "project" })
        #expect(sut.summary?.total == 7)
    }

    @Test("Expected exceptions are not counted as pending actions")
    func exceptionsAreNotActions() async {
        let sut = await loadedModel(scan: ProjectsFixture.scan(skills: [
            ProjectsFixture.skill(name: "synced", status: "managed_synced"),
            ProjectsFixture.skill(name: "claude-only", status: "expected_claude_only", codex: false)
        ]))

        #expect(sut.count(for: .toReview) == 0)
        #expect(sut.count(for: .exceptions) == 1)
        #expect(sut.allSkills.allSatisfy { !$0.requiresAction })
    }

    @Test("Filters select the expected rows")
    func filtersSelectExpectedRows() async {
        let sut = await loadedModel(scan: ProjectsFixture.scan(skills: [
            ProjectsFixture.skill(name: "synced", status: "managed_synced"),
            ProjectsFixture.skill(
                name: "importable", status: "local_codex_only", claude: false,
                severity: "attention", allowedActions: "[\"import\"]", importable: true
            ),
            ProjectsFixture.skill(name: "claude-only", status: "expected_claude_only", codex: false)
        ]))

        sut.filter = .all
        #expect(sut.visibleSkills.count == 3)

        sut.filter = .toReview
        #expect(sut.visibleSkills.map(\.name) == ["importable"])

        sut.filter = .synced
        #expect(sut.visibleSkills.map(\.name) == ["synced"])

        sut.filter = .exceptions
        #expect(sut.visibleSkills.map(\.name) == ["claude-only"])
    }

    @Test("Search matches the name and the canonical identifier")
    func searchMatchesNameAndCanonical() async {
        let sut = await loadedModel(scan: ProjectsFixture.scan(skills: [
            ProjectsFixture.skill(name: "01-spec", status: "managed_synced", canonicalId: "suggst.01-spec"),
            ProjectsFixture.skill(name: "commit", status: "managed_synced",
                                  scope: "shared", canonicalId: "shared.commit")
        ]))

        sut.searchText = "spec"
        #expect(sut.visibleSkills.map(\.name) == ["01-spec"])

        sut.searchText = "shared."
        #expect(sut.visibleSkills.map(\.name) == ["commit"])

        sut.searchText = "  "
        #expect(sut.visibleSkills.count == 2)
    }

    @Test("Clearing filters restores every row")
    func clearFiltersRestoresRows() async {
        let sut = await loadedModel(scan: ProjectsFixture.scan(skills: [
            ProjectsFixture.skill(name: "a", status: "managed_synced"),
            ProjectsFixture.skill(name: "b", status: "managed_synced")
        ]))

        sut.filter = .toReview
        sut.searchText = "zzz"
        #expect(sut.visibleSkills.isEmpty)
        #expect(sut.hasActiveFilter)

        sut.clearFilters()
        #expect(sut.visibleSkills.count == 2)
        #expect(!sut.hasActiveFilter)
    }

    @Test("Opening from a required action preselects the review filter")
    func selectionFromActionFocusesReview() async {
        let sut = await loadedModel(scan: ProjectsFixture.scan(skills: [
            ProjectsFixture.skill(name: "a", status: "managed_synced")
        ]))

        sut.select(projectNamed: "Suggst", focusActions: true)
        #expect(sut.filter == .toReview)

        sut.select(projectNamed: "Suggst", focusActions: false)
        #expect(sut.filter == .toReview)
    }

    @Test("Changing project resets the detail and the purely UI filters")
    func changingProjectResetsDetail() async {
        let sut = await loadedModel(
            scan: ProjectsFixture.scan(skills: [
                ProjectsFixture.skill(name: "a", status: "managed_synced")
            ]),
            projects: [("Suggst", "healthy", 0), ("Alpha", "healthy", 0)]
        )
        sut.filter = .synced
        sut.searchText = "a"

        sut.selectedProjectName = "Alpha"

        #expect(sut.scan == nil)
        #expect(sut.filter == .all)
        #expect(sut.searchText.isEmpty)
    }

    @Test("A failed scan keeps the project state and offers a retry")
    func failedScanKeepsProjectState() async {
        let backend = RoutingBackend(
            responses: ["project-overview": ProjectsFixture.overview(
                projects: [("Suggst", "healthy", 0)]
            )],
            failingRoutes: ["project-scan"]
        )
        let sut = ProjectsViewModel(service: ProjectSkillsService(backend: backend))

        await sut.loadProjects()
        sut.selectedProjectName = "Suggst"
        await sut.scanSelectedProject()

        #expect(sut.scan == nil)
        #expect(sut.scanError != nil)
        // The list entry keeps the state the backend reported.
        #expect(sut.selectedProject?.state == .healthy)
        #expect(sut.primaryActionTitle == "Analyser")
    }

    @Test("Summary reads as unverified rather than a confirmed zero")
    func summaryIsUnverifiedBeforeScan() async {
        let backend = RoutingBackend(responses: [
            "project-overview": ProjectsFixture.overview(projects: [("Suggst", "healthy", 0)])
        ])
        let sut = ProjectsViewModel(service: ProjectSkillsService(backend: backend))

        await sut.loadProjects()
        sut.selectedProjectName = "Suggst"

        #expect(sut.summary == nil)
        #expect(sut.allSkills.isEmpty)
    }

    @Test("Shared targets come from the backend and default to codex")
    func sharedTargetsComeFromBackend() async {
        let codexOnly = await loadedModel(scan: ProjectsFixture.scan(
            sharedTargets: ["codex"],
            skills: [ProjectsFixture.skill(name: "a", status: "managed_synced")]
        ))
        #expect(codexOnly.sharedTargets == ["codex"])

        let both = await loadedModel(scan: ProjectsFixture.scan(
            sharedTargets: ["claude", "codex"],
            skills: [ProjectsFixture.skill(name: "a", status: "managed_synced")]
        ))
        #expect(both.sharedTargets.sorted() == ["claude", "codex"])
    }
}
