import Foundation
import Testing
@testable import AI_System

/// Guards for spec 19: no state may be carried by colour alone, every status
/// must be announceable as text, and each case needs a symbol.
@Suite("Accessibility contracts")
struct AccessibilityContractTests {

    @Test("Every system state has a title and a symbol")
    func systemStatesAreDescribable() {
        for state in [SystemState.unknown, .checking, .healthy, .attention, .error] {
            #expect(!state.title.isEmpty)
            #expect(!state.symbolName.isEmpty)
        }
    }

    @Test("Every project state has a label and a symbol")
    func projectStatesAreDescribable() {
        for state in [ProjectState.unknown, .healthy, .attention, .error, .disabled] {
            #expect(!state.displayName.isEmpty)
            #expect(!state.symbolName.isEmpty)
        }
    }

    @Test("Every operation status has a label and a symbol")
    func operationStatusesAreDescribable() {
        for status in OperationStatus.allCases {
            #expect(!status.displayName.isEmpty)
            #expect(!status.symbolName.isEmpty)
        }
    }

    @Test("Every skill status has a title, an explanation and a symbol")
    func skillStatusesAreDescribable() {
        for status in SkillStatus.allCases {
            #expect(!status.displayName.isEmpty)
            #expect(!status.explanation.isEmpty)
            #expect(!status.symbolName.isEmpty)
        }
    }

    @Test("Every severity has a label and a symbol")
    func severitiesAreDescribable() {
        for severity in [ActionSeverity.attention, .error] {
            #expect(!severity.displayName.isEmpty)
            #expect(!severity.symbolName.isEmpty)
        }
    }

    @Test("Severity is not distinguished by red and green alone")
    func severityUsesDistinctSymbols() {
        // Red/green pairs must differ by shape too (19.3).
        #expect(SkillStatus.managedSynced.symbolName != SkillStatus.conflict.symbolName)
        #expect(ProjectState.healthy.symbolName != ProjectState.error.symbolName)
        #expect(SystemState.healthy.symbolName != SystemState.error.symbolName)
        #expect(ActionSeverity.attention.symbolName != ActionSeverity.error.symbolName)
    }

    @Test("Attention and error do not share a symbol")
    func attentionDiffersFromError() {
        #expect(SystemState.attention.symbolName != SystemState.error.symbolName)
        #expect(ProjectState.attention.symbolName != ProjectState.error.symbolName)
    }

    @Test("Every activity kind has a label and a symbol")
    func activityKindsAreDescribable() {
        for kind in ActivityKind.allCases {
            #expect(!kind.displayName.isEmpty)
            #expect(!kind.symbolName.isEmpty)
        }
    }

    @Test("Every filter has a label")
    func filtersAreLabelled() {
        for filter in SkillFilter.allCases {
            #expect(!filter.displayName.isEmpty)
        }
        for filter in ActivityFilter.allCases {
            #expect(!filter.displayName.isEmpty)
        }
    }

    @Test("Every navigation destination has a label and a symbol")
    func destinationsAreLabelled() {
        for section in AppSection.allCases {
            #expect(!section.displayName.isEmpty)
            #expect(!section.symbolName.isEmpty)
            #expect(!section.navigationTitle.isEmpty)
        }
    }

    @Test("Exactly three main destinations exist")
    func exactlyThreeDestinations() {
        #expect(AppSection.allCases.count == 3)
        #expect(Set(AppSection.allCases) == [.overview, .projects, .activity])
    }

    @Test("Every write state explains what happened on disk")
    func writeStatesAreExplained() {
        for state in [ActionWriteState.noChanges, .applied, .partialChanges, .rolledBack] {
            #expect(!state.description.isEmpty)
        }
    }

    @Test("Expected exceptions never count as pending actions")
    func exceptionsAreNeverActions() {
        #expect(SkillStatus.expectedClaudeOnly.isExpectedException)
        #expect(SkillStatus.expectedCodexOnly.isExpectedException)
        #expect(!SkillStatus.expectedClaudeOnly.requiresAction)
        #expect(!SkillStatus.expectedCodexOnly.requiresAction)
        #expect(!SkillStatus.managedSynced.requiresAction)
    }

}

/// The store is main-actor isolated, so long-text guards live in their own
/// isolated suite.
@MainActor
@Suite("Long content")
struct LongContentTests {

    @Test("Long names and messages are not truncated by the model layer")
    func longTextSurvivesTheModel() {
        let longName = String(repeating: "projet-au-nom-tres-long-", count: 12)
        let store = ActivityStore()
        let id = store.begin(
            kind: .sync, displayName: longName, scope: .project(longName)
        )
        store.finish(id, status: .succeeded, summary: String(repeating: "détail ", count: 200))

        let activity = store.activity(id)
        #expect(activity?.displayName == longName)
        #expect(activity?.targetDescription == longName)
        #expect((activity?.summary.count ?? 0) > 1000)
    }

    @Test("A long skill name is preserved for truncation at the view layer")
    func longSkillNameIsPreserved() {
        let longName = String(repeating: "skill-tres-long-", count: 20)
        let store = ActivityStore()
        let id = store.begin(
            kind: .importSkill,
            displayName: "Import de \(longName)",
            scope: .skill("Projet", longName)
        )

        #expect(store.activity(id)?.skillId == longName)
        #expect(store.activity(id)?.targetDescription.contains(longName) == true)
    }
}
