import SwiftUI

/// Confirms an import in business terms: what will exist afterwards, not which
/// script runs (spec 11.3). Technical paths stay in a collapsed section.
struct ImportSkillSheet: View {
    let skill: SkillRow
    let projectName: String
    let source: ImportSource
    let sharedTargets: [String]
    let isRunning: Bool
    let onCancel: () -> Void
    let onConfirm: (ImportSource) -> Void

    @State private var showTechnicalDetails = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.standard) {
            header
            Divider()
            outcome
            technicalDetails
            Divider()
            buttons
        }
        .padding(Spacing.sectionGap)
        .frame(minWidth: 460, maxWidth: 560)
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.micro) {
            Text("Importer « \(skill.name) »")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Projet \(projectName) · détecté dans \(source.displayName)")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    private var outcome: some View {
        VStack(alignment: .leading, spacing: Spacing.related) {
            Text("Après l'import")
                .font(.headline)

            Label(
                "AI System gérera ce skill et deviendra sa source de référence.",
                systemImage: "checkmark.circle"
            )
            .font(.callout)

            Label(
                destinationSentence,
                systemImage: "arrow.trianglehead.branch"
            )
            .font(.callout)

            // The backend reports no overwrite for an import, so no warning is
            // invented here (spec 11.3).
            Label(
                "Le contenu actuel de \(source.displayName) est utilisé tel quel.",
                systemImage: "doc.on.doc"
            )
            .font(.callout)
            .foregroundStyle(.secondary)
        }
    }

    private var destinationSentence: String {
        let targets = sharedTargets.isEmpty ? [source.rawValue] : sharedTargets
        let names = targets.map { $0 == "claude" ? "Claude" : "Codex" }.sorted()
        if names.count == 1 {
            return "Les exports seront maintenus pour \(names[0])."
        }
        return "Les exports seront maintenus pour \(names.joined(separator: " et "))."
    }

    private var technicalDetails: some View {
        DisclosureGroup("Détails", isExpanded: $showTechnicalDetails) {
            VStack(alignment: .leading, spacing: Spacing.related) {
                detailRow("Identifiant proposé", skill.candidateCanonicalId ?? "—")
                detailRow("Source", skill.paths.codex ?? skill.paths.claude ?? "—")
                detailRow("Destination gérée", skill.paths.canonical ?? "—")
            }
            .padding(.top, Spacing.related)
        }
        .font(.callout)
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)
                .lineLimit(3)
                .truncationMode(.middle)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var buttons: some View {
        HStack {
            Button("Annuler", role: .cancel, action: onCancel)
                .keyboardShortcut(.cancelAction)
                .disabled(isRunning)

            Spacer()

            Button {
                onConfirm(source)
            } label: {
                if isRunning {
                    HStack(spacing: Spacing.related) {
                        ProgressView().controlSize(.small)
                        Text("Import en cours…")
                    }
                } else {
                    Text("Importer le skill")
                }
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)
            // Blocks the double submission at the UI level too (spec 11.4).
            .disabled(isRunning)
        }
    }
}
