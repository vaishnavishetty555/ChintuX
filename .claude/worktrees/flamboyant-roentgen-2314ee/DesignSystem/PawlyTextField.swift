import SwiftUI

/// Modern text field. Subtle border, rounded, clear focus state.
struct PawlyTextField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var keyboard: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if !label.isEmpty {
                Text(label)
                    .font(PawlyFont.captionSmall)
                    .foregroundStyle(PawlyColors.slate)
                    .textCase(.uppercase)
            }
            TextField(placeholder, text: $text)
                .font(PawlyFont.bodyLarge)
                .foregroundStyle(PawlyColors.ink)
                .textInputAutocapitalization(autocapitalization)
                .keyboardType(keyboard)
                .focused($focused)
                .padding(.horizontal, 14)
                .padding(.vertical, 13)
                .frame(minHeight: 48)
                .background(
                    RoundedRectangle(cornerRadius: Radius.input, style: .continuous)
                        .fill(PawlyColors.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.input, style: .continuous)
                        .stroke(focused ? PawlyColors.forest.opacity(0.55) : PawlyColors.hairline,
                                lineWidth: focused ? 1.25 : 0.75)
                )
                .animation(.easeOut(duration: 0.14), value: focused)
        }
    }
}
