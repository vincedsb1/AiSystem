import SwiftUI

struct ContentView: View {
    @State private var center = CommandCenter()
    @State private var selection: SidebarSection = .dashboard

    private let sidebarSections: [SidebarSection] = [
        .dashboard, .diffusion, .projects, .reports, .documentation, .tools, .logs
    ]

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selection, sections: sidebarSections)
        } detail: {
            detailView
                .navigationTitle(selection.displayName)
        }
        .environment(center)
        .frame(minWidth: 760, minHeight: 480)
    }

    @ViewBuilder
    private var detailView: some View {
        switch selection {
        case .dashboard:
            DashboardView(selection: $selection)
        case .diffusion:
            DiffusionView()
        case .projects:
            ProjectsView()
        case .reports:
            ReportsView()
        case .documentation:
            DocumentationView()
        case .tools:
            ToolsView()
        case .logs:
            LogsView()
        }
    }
}

#Preview {
    ContentView()
}
