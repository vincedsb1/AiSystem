import SwiftUI

struct SidebarView: View {
    @Binding var selection: SidebarSection
    let sections: [SidebarSection]

    var body: some View {
        List(selection: $selection) {
            ForEach(sections) { section in
                Label(section.displayName, systemImage: section.symbolName)
                    .tag(section)
            }
        }
        .navigationTitle("AI System")
        .listStyle(.sidebar)
    }
}
