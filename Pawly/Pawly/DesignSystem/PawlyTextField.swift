import SwiftUI

/// Themed text-field wrapper for consistent cream/sand styling.
struct PawlyTextField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var keyboard: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(label)
                .font(PawlyFont.caption)
                .foregroundStyle(PawlyColors.slate)
            TextField(placeholder, text: $text)
                .font(PawlyFont.bodyLarge)
                .foregroundStyle(PawlyColors.ink)
                .textInputAutocapitalization(autocapitalization)
                .keyboardType(keyboard)
                .padding(.horizontal, Spacing.s)
                .padding(.vertical, Spacing.s)
                .frame(minHeight: Spacing.tapTargetMin)
                .background(
                    RoundedRectangle(cornerRadius: Radius.input, style: .continuous)
                        .fill(PawlyColors.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.input, style: .continuous)
                        .stroke(PawlyColors.sand, lineWidth: 1)
                )
        }
    }
}
