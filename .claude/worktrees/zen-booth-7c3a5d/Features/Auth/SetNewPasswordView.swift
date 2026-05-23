import SwiftUI

/// Shown when the user opens the password-reset deep link.
/// Supabase has already validated the recovery token — we just need the new password.
struct SetNewPasswordView: View {
    @EnvironmentObject private var authService: AuthService
    @Environment(\.dismiss) private var dismiss

    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var isSaving = false
    @State private var didSave = false
    @State private var errorMessage: String?

    private var canSave: Bool {
        newPassword.count >= 6 && newPassword == confirmPassword && !isSaving
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                Spacer().frame(height: 8)

                // Icon
                ZStack {
                    Circle()
                        .fill(Color(hex: "#EAF6F4"))
                        .frame(width: 72, height: 72)
                    Image(systemName: "lock.rotation")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(Color(hex: "#47C1B1"))
                }

                VStack(spacing: 6) {
                    Text("Set new password")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Color(hex: "#1A237E"))
                    Text("Choose a strong password — at least 6 characters.")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: "#6C757D"))
                        .multilineTextAlignment(.center)
                }

                if didSave {
                    VStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(Color(hex: "#47C1B1"))
                        Text("Password updated!")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color(hex: "#1A237E"))
                        Text("You're now signed in. You can close this screen.")
                            .font(.system(size: 14))
                            .foregroundStyle(Color(hex: "#6C757D"))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 20)
                } else {
                    VStack(spacing: 14) {
                        // New password
                        HStack {
                            Image(systemName: "lock")
                                .foregroundStyle(Color(hex: "#7B61FF"))
                                .frame(width: 20)
                            if showPassword {
                                TextField("New password", text: $newPassword)
                            } else {
                                SecureField("New password", text: $newPassword)
                            }
                            Button {
                                showPassword.toggle()
                            } label: {
                                Image(systemName: showPassword ? "eye.slash" : "eye")
                                    .foregroundStyle(Color(hex: "#A0A0A0"))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color(hex: "#F7F8FA"))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(Color(hex: "#E9ECEF"), lineWidth: 1)
                                )
                        )

                        // Confirm password
                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundStyle(Color(hex: "#47C1B1"))
                                .frame(width: 20)
                            SecureField("Confirm password", text: $confirmPassword)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color(hex: "#F7F8FA"))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(
                                            !confirmPassword.isEmpty && confirmPassword != newPassword
                                                ? Color.red.opacity(0.4)
                                                : Color(hex: "#E9ECEF"),
                                            lineWidth: 1
                                        )
                                )
                        )

                        if !confirmPassword.isEmpty && confirmPassword != newPassword {
                            Text("Passwords don't match")
                                .font(.system(size: 12))
                                .foregroundStyle(.red.opacity(0.8))
                        }

                        if let err = errorMessage {
                            Text(err)
                                .font(.system(size: 13))
                                .foregroundStyle(.red.opacity(0.8))
                                .multilineTextAlignment(.center)
                        }

                        Button {
                            Task { await save() }
                        } label: {
                            HStack {
                                if isSaving {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Update Password")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 25, style: .continuous)
                                    .fill(canSave ? Color(hex: "#47C1B1") : Color(hex: "#A0A0A0"))
                            )
                        }
                        .disabled(!canSave)
                        .buttonStyle(.plain)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 28)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(didSave ? "Done" : "Cancel") {
                        authService.isInPasswordRecovery = false
                        dismiss()
                    }
                    .foregroundStyle(Color(hex: "#47C1B1"))
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func save() async {
        isSaving = true
        errorMessage = nil
        let success = await authService.setNewPassword(newPassword)
        isSaving = false
        if success {
            didSave = true
            // Auto-dismiss after a moment
            try? await Task.sleep(for: .seconds(2))
            authService.isInPasswordRecovery = false
            dismiss()
        } else {
            errorMessage = authService.authError ?? "Failed to update password. Please try again."
        }
    }
}

#Preview {
    SetNewPasswordView()
        .environmentObject(AuthService.shared)
}
