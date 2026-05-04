import SwiftUI

// MARK: - Primary (Forest)

struct PawlyPrimaryButtonStyle: ButtonStyle {
    var expands: Bool = true
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 22)
            .padding(.vertical, 14)
            .frame(minHeight: 48)
            .frame(maxWidth: expands ? .infinity : nil)
            .background(
                RoundedRectangle(cornerRadius: Radius.button, style: .continuous)
                    .fill(PawlyColors.forest)
                    .opacity(configuration.isPressed ? 0.85 : 1.0)
            )
            .shadow(color: configuration.isPressed ? Color.clear : PawlyColors.forest.opacity(0.25), radius: 8, x: 0, y: 3)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Secondary (outlined)

struct PawlySecondaryButtonStyle: ButtonStyle {
    var expands: Bool = true
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(PawlyColors.forest)
            .padding(.horizontal, 22)
            .padding(.vertical, 14)
            .frame(minHeight: 48)
            .frame(maxWidth: expands ? .infinity : nil)
            .background(
                RoundedRectangle(cornerRadius: Radius.button, style: .continuous)
                    .stroke(PawlyColors.forest, lineWidth: 1.5)
                    .background(
                        RoundedRectangle(cornerRadius: Radius.button, style: .continuous)
                            .fill(PawlyColors.surface.opacity(configuration.isPressed ? 0.8 : 0.0))
                    )
            )
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Destructive

struct PawlyDestructiveButtonStyle: ButtonStyle {
    var expands: Bool = true
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(PawlyColors.alert)
            .padding(.horizontal, 22)
            .padding(.vertical, 14)
            .frame(minHeight: 48)
            .frame(maxWidth: expands ? .infinity : nil)
            .background(
                RoundedRectangle(cornerRadius: Radius.button, style: .continuous)
                    .fill(PawlyColors.alert.opacity(configuration.isPressed ? 0.15 : 0.08))
            )
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
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