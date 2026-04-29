import SwiftUI

/// PRD §4.6 — Reusable card container with warm surface, soft border, 12dp radius.
struct PawlyCard<Content: View>: View {
    var padding: CGFloat = Spacing.cardPadding
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .fill(PawlyColors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .stroke(PawlyColors.sand, lineWidth: 1)
                    .opacity(0.6)
            )
    }
}
