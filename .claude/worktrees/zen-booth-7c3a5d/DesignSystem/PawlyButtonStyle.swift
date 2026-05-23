import SwiftUI

// MARK: - Primary

struct PawlyPrimaryButtonStyle: ButtonStyle {
    var expands: Bool = true
    var compact: Bool = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: compact ? 14 : 15, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, compact ? 16 : 22)
            .padding(.vertical, compact ? 10 : 14)
            .frame(minHeight: compact ? 40 : 50)
            .frame(maxWidth: expands ? .infinity : nil)
            .background(
                RoundedRectangle(cornerRadius: Radius.button, style: .continuous)
                    .fill(PawlyColors.forest)
                    .opacity(configuration.isPressed ? 0.88 : 1.0)
            )
            .scaleEffect(configuration.isPressed ? 0.985 : 1.0)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }
}

// MARK: - Secondary (outlined / tonal)

struct PawlySecondaryButtonStyle: ButtonStyle {
    var expands: Bool = true
    var compact: Bool = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: compact ? 14 : 15, weight: .semibold))
            .foregroundStyle(PawlyColors.forest)
            .padding(.horizontal, compact ? 16 : 22)
            .padding(.vertical, compact ? 10 : 14)
            .frame(minHeight: compact ? 40 : 50)
            .frame(maxWidth: expands ? .infinity : nil)
            .background(
                RoundedRectangle(cornerRadius: Radius.button, style: .continuous)
                    .fill(configuration.isPressed ? PawlyColors.forestSoft : PawlyColors.forestSoft.opacity(0.6))
            )
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }
}

// MARK: - Ghost

struct PawlyGhostButtonStyle: ButtonStyle {
    var compact: Bool = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: compact ? 13 : 14, weight: .semibold))
            .foregroundStyle(PawlyColors.forest)
            .padding(.horizontal, compact ? 12 : 16)
            .padding(.vertical, compact ? 8 : 10)
            .background(
                RoundedRectangle(cornerRadius: Radius.button, style: .continuous)
                    .fill(configuration.isPressed ? PawlyColors.forestSoft.opacity(0.6) : .clear)
            )
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
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
            .frame(minHeight: 50)
            .frame(maxWidth: expands ? .infinity : nil)
            .background(
                RoundedRectangle(cornerRadius: Radius.button, style: .continuous)
                    .fill(configuration.isPressed ? PawlyColors.alertSoft.opacity(1.4) : PawlyColors.alertSoft)
            )
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PawlyPrimaryButtonStyle {
    static var pawlyPrimary: PawlyPrimaryButtonStyle { PawlyPrimaryButtonStyle() }
    static func pawlyPrimary(expands: Bool = true, compact: Bool = false) -> PawlyPrimaryButtonStyle {
        PawlyPrimaryButtonStyle(expands: expands, compact: compact)
    }
}
extension ButtonStyle where Self == PawlySecondaryButtonStyle {
    static var pawlySecondary: PawlySecondaryButtonStyle { PawlySecondaryButtonStyle() }
    static func pawlySecondary(expands: Bool = true, compact: Bool = false) -> PawlySecondaryButtonStyle {
        PawlySecondaryButtonStyle(expands: expands, compact: compact)
    }
}
extension ButtonStyle where Self == PawlyGhostButtonStyle {
    static var pawlyGhost: PawlyGhostButtonStyle { PawlyGhostButtonStyle() }
}
extension ButtonStyle where Self == PawlyDestructiveButtonStyle {
    static var pawlyDestructive: PawlyDestructiveButtonStyle { PawlyDestructiveButtonStyle() }
}
