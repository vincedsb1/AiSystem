import Foundation
import Testing
@testable import AI_System

// MARK: - Fixtures

enum AddProjectFixture {

    static func inspection(
        path: String = "/tmp/NewProject",
        suggestedName: String = "NewProject",
        detected: [String] = ["codex"],
        proposed: [String]? = nil,
        alreadyRegistered: String? = nil,
        defaultInstallNow: Bool = false
    ) -> String {
        let detectedValue = detected.map { "\"\($0)\"" }.joined(separator: ",")
        let proposedValue = (proposed ?? (detected.isEmpty ? ["codex"] : detected))
            .map { "\"\($0)\"" }.joined(separator: ",")
        let registered = alreadyRegistered.map {
            """
            {"name":"NewProject","enabled":true,"reason":"\($0)"}
            """
        } ?? "null"

        return """
        {
          "schemaVersion":1,"status":"ok","generatedAt":"2026-08-20T17:34:57Z",
          "action":"inspect-folder","path":"\(path)",
          "suggestedName":"\(suggestedName)",
          "detectedTargets":[\(detectedValue)],
          "proposedTargets":[\(proposedValue)],
          "alreadyRegistered":\(registered),
          "defaultInstallNow":\(defaultInstallNow),
          "error":null
        }
        """
    }

    static let addSuccess = """
    {
      "schemaVersion":1,"status":"ok","generatedAt":"2026-08-20T17:34:57Z",
      "action":"add-project","project":"NewProject","skill":null,
      "outcome":"added","writeState":"applied",
      "summary":"Le projet NewProject a été ajouté.",
      "changes":{"created":1,"updated":0,"unchanged":0,
        "root":"/tmp/NewProject","targets":["codex"],"sharedSkills":13},
      "error":null
    }
    """

    static let duplicateName = """
    {
      "schemaVersion":1,"status":"error","generatedAt":"2026-08-20T17:34:57Z",
      "action":"add-project","project":"NewProject","skill":null,
      "outcome":"failed","writeState":"no_changes",
      "summary":"Un projet porte déjà ce nom : NewProject","changes":null,
      "error":{"code":"project_exists",
        "message":"Un projet porte déjà ce nom : NewProject",
        "details":{},"retryable":false,"writeState":"no_changes",
        "suggestedAction":"choose_another_name"}
    }
    """

    static let folderUnreadable = """
    {
      "schemaVersion":1,"status":"error","generatedAt":"2026-08-20T17:34:57Z",
      "action":"inspect-folder","path":"/tmp/ghost",
      "suggestedName":"","detectedTargets":[],"proposedTargets":[],
      "alreadyRegistered":null,"defaultInstallNow":false,
      "error":{"code":"folder_unreadable",
        "message":"Dossier introuvable ou inaccessible : /tmp/ghost",
        "details":{},"retryable":false,"writeState":"no_changes",
        "suggestedAction":null}
    }
    """
}

// MARK: - Tests

@MainActor
@Suite("Add project")
struct AddProjectViewModelTests {

    private func model(_ responses: [String: String]) -> AddProjectViewModel {
        AddProjectViewModel(
            service: ProjectSkillsService(backend: CountingBackend(responses: responses))
        )
    }

    @Test("Nothing can be submitted before a folder is chosen")
    func cannotSubmitWithoutFolder() {
        let sut = model([:])

        #expect(sut.selectedPath == nil)
        #expect(!sut.canSubmit)
    }

    @Test("Inspecting a folder prefills the name and the detected targets")
    func inspectionPrefillsForm() async {
        let sut = model(["project-inspect-folder": AddProjectFixture.inspection()])

        await sut.inspect(path: "/tmp/NewProject")

        #expect(sut.name == "NewProject")
        #expect(sut.targets == ["codex"])
        #expect(sut.selectedPath == "/tmp/NewProject")
        #expect(sut.canSubmit)
    }

    @Test("Both runtimes detected are both preselected")
    func detectsBothRuntimes() async {
        let sut = model([
            "project-inspect-folder": AddProjectFixture.inspection(
                detected: ["codex", "claude"]
            )
        ])

        await sut.inspect(path: "/tmp/NewProject")

        #expect(sut.targets == ["codex", "claude"])
    }

    @Test("A folder with no runtime falls back to the backend proposal")
    func fallsBackToProposedTargets() async {
        let sut = model([
            "project-inspect-folder": AddProjectFixture.inspection(detected: [])
        ])

        await sut.inspect(path: "/tmp/Bare")

        #expect(sut.targets == ["codex"])
        #expect(sut.inspection?.detectedTargets.isEmpty == true)
    }

    @Test("A path with spaces survives the round trip")
    func handlesPathWithSpaces() async {
        let sut = model([
            "project-inspect-folder": AddProjectFixture.inspection(
                path: "/tmp/My Project", suggestedName: "My Project"
            )
        ])

        await sut.inspect(path: "/tmp/My Project")

        #expect(sut.selectedPath == "/tmp/My Project")
        #expect(sut.name == "My Project")
    }

    @Test("An already registered folder blocks submission and explains why")
    func blocksAlreadyRegisteredFolder() async {
        let sut = model([
            "project-inspect-folder": AddProjectFixture.inspection(
                alreadyRegistered: "same_root"
            )
        ])

        await sut.inspect(path: "/tmp/NewProject")

        #expect(sut.isBlocked)
        #expect(!sut.canSubmit)
        #expect(sut.errorMessage?.contains("déjà déclaré") == true)
    }

    @Test("An unreadable folder reports the backend error and clears the form")
    func reportsUnreadableFolder() async {
        let sut = model(["project-inspect-folder": AddProjectFixture.folderUnreadable])

        await sut.inspect(path: "/tmp/ghost")

        #expect(sut.inspection == nil)
        #expect(!sut.canSubmit)
        #expect(sut.errorMessage?.contains("introuvable") == true)
    }

    @Test("An empty name blocks submission")
    func emptyNameBlocksSubmission() async {
        let sut = model(["project-inspect-folder": AddProjectFixture.inspection()])
        await sut.inspect(path: "/tmp/NewProject")

        sut.name = "   "
        #expect(!sut.canSubmit)

        sut.name = "Valid"
        #expect(sut.canSubmit)
    }

    @Test("The last target cannot be removed")
    func keepsAtLeastOneTarget() async {
        let sut = model(["project-inspect-folder": AddProjectFixture.inspection()])
        await sut.inspect(path: "/tmp/NewProject")

        sut.toggle(target: "codex")

        #expect(sut.targets == ["codex"])
    }

    @Test("Toggling adds and removes a target")
    func togglesTargets() async {
        let sut = model([
            "project-inspect-folder": AddProjectFixture.inspection(
                detected: ["codex", "claude"]
            )
        ])
        await sut.inspect(path: "/tmp/NewProject")

        sut.toggle(target: "claude")
        #expect(sut.targets == ["codex"])

        sut.toggle(target: "claude")
        #expect(sut.targets == ["codex", "claude"])
    }

    @Test("A successful add exposes the project so the caller can select it")
    func successfulAddExposesProject() async {
        let sut = model([
            "project-inspect-folder": AddProjectFixture.inspection(),
            "project-add": AddProjectFixture.addSuccess
        ])
        await sut.inspect(path: "/tmp/NewProject")

        await sut.submit()

        #expect(sut.addedProjectName == "NewProject")
        #expect(sut.errorMessage == nil)
    }

    @Test("A duplicate name states that nothing was added")
    func duplicateNameStatesNoChange() async {
        let sut = model([
            "project-inspect-folder": AddProjectFixture.inspection(),
            "project-add": AddProjectFixture.duplicateName
        ])
        await sut.inspect(path: "/tmp/NewProject")

        await sut.submit()

        #expect(sut.addedProjectName == nil)
        // Spec 13.4: the error must say whether the project was added.
        #expect(sut.errorMessage?.contains("Aucune modification") == true)
    }

    @Test("A double click submits only once")
    func doubleClickSubmitsOnce() async {
        let backend = CountingBackend(
            responses: [
                "project-inspect-folder": AddProjectFixture.inspection(),
                "project-add": AddProjectFixture.addSuccess
            ],
            delay: .milliseconds(120)
        )
        let sut = AddProjectViewModel(service: ProjectSkillsService(backend: backend))
        await sut.inspect(path: "/tmp/NewProject")

        async let first: Void = sut.submit()
        try? await Task.sleep(for: .milliseconds(20))
        await sut.submit()
        await first

        #expect(backend.callCount(for: "project-add") == 1)
    }

    @Test("The backend's install-now default is surfaced, not invented")
    func surfacesBackendInstallDefault() async {
        let sut = model([
            "project-inspect-folder": AddProjectFixture.inspection(defaultInstallNow: false)
        ])

        await sut.inspect(path: "/tmp/NewProject")

        #expect(sut.inspection?.defaultInstallNow == false)
    }
}
