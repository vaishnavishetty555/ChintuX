import SwiftUI

/// Surface card. Subtle elevation, hairline border. No "plastic" shadows.
struct PawlyCard<Content: View>: View {
    var padding: CGFloat = Spacing.cardPadding
    var radius: CGFloat = Radius.card
    var elevated: Bool = true
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(PawlyColors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(PawlyColors.hairline, lineWidth: 0.75)
            )
            .shadow(color: elevated ? PawlyColors.shadowWarm : .clear,
                    radius: 14, x: 0, y: 4)
    }
}

/// Inline section header used across views.
struct SectionHeader: View {
    let title: String
    var trailingTitle: String?
    var trailingTint: Color = PawlyColors.forest
    var trailingAction: (() -> Void)?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(PawlyFont.headingMedium)
                .foregroundStyle(PawlyColors.ink)
            Spacer()
            if let trailingTitle, let trailingAction {
                Button(action: trailingAction) {
                    Text(trailingTitle)
                        .font(PawlyFont.label)
                        .foregroundStyle(trailingTint)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
