import SwiftUI

/// Modern card container. Clean white surface, subtle border, no heavy shadows.
/// Subtle shadow for depth without looking "plastic".
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
                    .stroke(PawlyColors.sand.opacity(0.5), lineWidth: 0.75)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}