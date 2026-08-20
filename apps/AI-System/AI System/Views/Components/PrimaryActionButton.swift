import SwiftUI

struct PrimaryActionButton: View {
    let title: String
    let systemImage: String
    let disabled: Bool
    let action: () async -> Void

    var body: some View {
        Button {
            Task { await action() }
        } label: {
            Label(title, systemImage: systemImage)
        }
        .disabled(disabled)
    }
}
