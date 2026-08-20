import SwiftUI

struct ContentView: View {
    @State private var center = CommandCenter()
    @State private var activityStore = ActivityStore()
    @State private var selection: AppSection = .overview
    @AppStorage("selectedAppSection") private var savedSelection: String = AppSection.overview.rawValue

    /// Project handed over by another destination, consumed by Projects.
    @State private var pendingProjectSelection: String?

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
        .environment(center)
        .environment(activityStore)
        .frame(minWidth: 900, minHeight: 620)
        .onAppear {
            // Restore previously selected section
            if let section = AppSection(rawValue: savedSelection) {
                selection = section
            }
        }
        .onChange(of: selection) { oldValue, newValue in
            // Save the selected section
            savedSelection = newValue.rawValue
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

    @ViewBuilder
    private var detailView: some View {
        switch selection {
        case .overview:
            OverviewView(onOpenProject: openProject, onOpenActivity: openActivity)
        case .projects:
            ProjectsView(pendingSelection: $pendingProjectSelection)
        case .activity:
            ActivityView()
        }
    }
}

#Preview {
    ContentView()
}
