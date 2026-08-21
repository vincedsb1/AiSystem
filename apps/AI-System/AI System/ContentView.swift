import AppKit
import SwiftUI

struct ContentView: View {
    @State private var activityStore = ActivityStore()
    @State private var commandCenter = CommandCenter()
    @State private var dataStore = AppDataStore()
    @State private var selection: AppSection = .overview
    @AppStorage("selectedAppSection") private var savedSelection: String = AppSection.overview.rawValue

    /// Project handed over by another destination, consumed by Projects.
    @State private var pendingProjectSelection: String?
    @State private var pendingSkillSelection: QuickCommandSkillSelection?
    @State private var pendingSyncProject: String?
    @State private var isQuickCommandPresented = false

    private let sections: [AppSection] = AppSection.allCases.sorted { $0.sortOrder < $1.sortOrder }

    var body: some View {
        NavigationSplitView {
            // MARK: - Sidebar
            List(selection: $selection) {
                ForEach(sections) { section in
                    NavigationLink(value: section) {
                        Label(section.displayName, systemImage: section.symbolName)
                    }
                    .tag(section)
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 190, ideal: 220, max: 280)
        } detail: {
            // MARK: - Detail Content
            detailView
                .navigationTitle(selection.navigationTitle)
        }
        .environment(activityStore)
        .environment(commandCenter)
        .environment(dataStore)
        .frame(minWidth: 900, minHeight: 620)
        .toolbar {
            ToolbarItem {
                OperationStatusControl(
                    commandCenter: commandCenter,
                    onOpenActivity: openActivity
                )
            }
        }
        .onAppear {
            // Restore previously selected section
            if let section = AppSection(rawValue: savedSelection) {
                selection = section
                dataStore.activeSection = section
            }
        }
        .onChange(of: selection) { oldValue, newValue in
            // Save the selected section
            savedSelection = newValue.rawValue
            dataStore.activeSection = newValue
        }
        .onReceive(NotificationCenter.default.publisher(for: .quickCommandRequested)) { _ in
            guard !isQuickCommandPresented else { return }
            isQuickCommandPresented = true
        }
        .sheet(isPresented: $isQuickCommandPresented) {
            QuickCommandView(
                activityStore: activityStore,
                dataStore: dataStore,
                commandCenter: commandCenter,
                onIntent: handleQuickCommand,
                onDismiss: { isQuickCommandPresented = false }
            )
        }
    }

    /// FR-NAV-02: opening a required action selects Projects and the project
    /// it concerns.
    private func openProject(_ name: String) {
        pendingProjectSelection = name
        selection = .projects
    }

    /// FR-NAV-03: opening an activity from an inline error selects Activité
    /// and that record.
    private func openActivity(_ id: UUID) {
        activityStore.selectedActivityId = id
        selection = .activity
    }

    private func handleQuickCommand(_ intent: QuickCommandIntent) {
        isQuickCommandPresented = false

        switch intent {
        case .navigate(let section):
            selection = section
        case .openProject(let name):
            pendingProjectSelection = name
            selection = .projects
        case .revealSkill(let project, let skill):
            pendingSkillSelection = QuickCommandSkillSelection(project: project, skill: skill)
            selection = .projects
        case .openActivity(let id):
            openActivity(id)
        case .runCheck:
            selection = .overview
            Task { @MainActor in
                await Task.yield()
                NotificationCenter.default.post(name: .runCheckRequested, object: nil)
            }
        case .prepareProjectSync(let project):
            pendingSyncProject = project
            selection = .projects
        case .addProject:
            selection = .projects
            Task { @MainActor in
                await Task.yield()
                NotificationCenter.default.post(name: .addProjectRequested, object: nil)
            }
        case .openResource(let action):
            Task { await ProjectSkillsService().openResource(action) }
        case .openSettings:
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        }
    }

    @ViewBuilder
    private var detailView: some View {
        switch selection {
        case .overview:
            OverviewView(onOpenProject: openProject, onOpenActivity: openActivity)
        case .projects:
            ProjectsView(
                pendingSelection: $pendingProjectSelection,
                pendingSkillSelection: $pendingSkillSelection,
                pendingSyncProject: $pendingSyncProject
            )
        case .activity:
            ActivityView()
        }
    }
}

#Preview {
    ContentView()
}
