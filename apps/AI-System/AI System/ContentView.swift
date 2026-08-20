import SwiftUI

struct ContentView: View {
    @State private var center = CommandCenter()
    @State private var selection: AppSection = .overview
    @AppStorage("selectedAppSection") private var savedSelection: String = AppSection.overview.rawValue

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

    @ViewBuilder
    private var detailView: some View {
        switch selection {
        case .overview:
            OverviewPlaceholderView()
        case .projects:
            ProjectsPlaceholderView()
        case .activity:
            ActivityPlaceholderView()
        }
    }
}

// MARK: - Placeholder Views for UX-02

struct OverviewPlaceholderView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.grid.2x2.fill")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Vue d'ensemble")
                .font(.headline)

            Text("État global du système AI (UX-03)")
                .font(.caption)
                .foregroundStyle(.secondary)

            Divider()
                .padding(.vertical, 8)

            Text("À implémenter dans UX-03:")
                .font(.caption)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 4) {
                Text("• État global (unknown, checking, healthy, attention, error)")
                Text("• Date de dernière vérification")
                Text("• Actions requises prioritaires")
                Text("• Résumé des projets")
                Text("• Activité récente")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct ProjectsPlaceholderView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder.fill")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Projets")
                .font(.headline)

            Text("Consultation et gestion des projets (UX-04, UX-05, UX-06)")
                .font(.caption)
                .foregroundStyle(.secondary)

            Divider()
                .padding(.vertical, 8)

            Text("À implémenter:")
                .font(.caption)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 4) {
                Text("• UX-04: Liste projets, détail, skills (lecture seule)")
                Text("• UX-05: Import et synchronisation")
                Text("• UX-06: Ajout guidé de projet")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct ActivityPlaceholderView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "list.bullet.rectangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Activité")
                .font(.headline)

            Text("Résultats, rapports et logs contextualisés (UX-07)")
                .font(.caption)
                .foregroundStyle(.secondary)

            Divider()
                .padding(.vertical, 8)

            Text("À implémenter dans UX-07:")
                .font(.caption)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 4) {
                Text("• Historique des opérations")
                Text("• Statuts et résumés")
                Text("• Détails techniques repliés")
                Text("• Filtres et recherche")
                Text("• Rapports et logs")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

#Preview {
    ContentView()
}
