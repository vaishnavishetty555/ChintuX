import SwiftUI

/// Modern text-field with clean surface, subtle border, and rounded styling.
struct PawlyTextField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var keyboard: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            if !label.isEmpty {
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(PawlyColors.slate)
            }
            TextField(placeholder, text: $text)
                .font(PawlyFont.bodyLarge)
                .foregroundStyle(PawlyColors.ink)
                .textInputAutocapitalization(autocapitalization)
                .keyboardType(keyboard)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .frame(minHeight: 46)
                .background(
                    RoundedRectangle(cornerRadius: Radius.input, style: .continuous)
                        .fill(PawlyColors.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.input, style: .continuous)
                        .stroke(PawlyColors.sand.opacity(0.6), lineWidth: 0.75)
                )
        }
    }
}