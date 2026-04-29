import SwiftUI

// MARK: - Primary (Forest)

struct PawlyPrimaryButtonStyle: ButtonStyle {
    var expands: Bool = true
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PawlyFont.headingMedium)
            .foregroundStyle(Color.white)
            .padding(.vertical, 14)
            .padding(.horizontal, 24)
            .frame(minHeight: Spacing.tapTargetMin)
            .frame(maxWidth: expands ? .infinity : nil)
            .background(
                RoundedRectangle(cornerRadius: Radius.button, style: .continuous)
                    .fill(PawlyColors.forest)
                    .opacity(configuration.isPressed ? 0.85 : 1.0)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(Motion.micro, value: configuration.isPressed)
    }
}

// MARK: - Secondary (outlined forest)

struct PawlySecondaryButtonStyle: ButtonStyle {
    var expands: Bool = true
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PawlyFont.headingMedium)
            .foregroundStyle(PawlyColors.forest)
            .padding(.vertical, 14)
            .padding(.horizontal, 24)
            .frame(minHeight: Spacing.tapTargetMin)
            .frame(maxWidth: expands ? .infinity : nil)
            .background(
                RoundedRectangle(cornerRadius: Radius.button, style: .continuous)
                    .stroke(PawlyColors.forest, lineWidth: 1.5)
                    .background(
                        RoundedRectangle(cornerRadius: Radius.button, style: .continuous)
                            .fill(PawlyColors.surface.opacity(configuration.isPressed ? 0.6 : 0.0))
                    )
            )
            .animation(Motion.micro, value: configuration.isPressed)
    }
}

// MARK: - Destructive

struct PawlyDestructiveButtonStyle: ButtonStyle {
    var expands: Bool = true
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PawlyFont.headingMedium)
            .foregroundStyle(PawlyColors.alert)
            .padding(.vertical, 14)
            .padding(.horizontal, 24)
            .frame(minHeight: Spacing.tapTargetMin)
            .frame(maxWidth: expands ? .infinity : nil)
            .background(
                RoundedRectangle(cornerRadius: Radius.button, style: .continuous)
                    .fill(PawlyColors.alert.opacity(configuration.isPressed ? 0.15 : 0.08))
            )
            .animation(Motion.micro, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PawlyPrimaryButtonStyle {
    static var pawlyPrimary: PawlyPrimaryButtonStyle { PawlyPrimaryButtonStyle() }
}
extension ButtonStyle where Self == PawlySecondaryButtonStyle {
    static var pawlySecondary: PawlySecondaryButtonStyle { PawlySecondaryButtonStyle() }
}
extension ButtonStyle where Self == PawlyDestructiveButtonStyle {
    static var pawlyDestructive: PawlyDestructiveButtonStyle { PawlyDestructiveButtonStyle() }
}
