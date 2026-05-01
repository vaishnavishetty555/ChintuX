import SwiftUI

/// PRD — Authentication entry screen. Toggles between Log In and Sign Up.
struct AuthView: View {
    @EnvironmentObject private var authService: AuthService
    @State private var mode: AuthMode = .login

    enum AuthMode { case login, signup }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                hero

                VStack(spacing: Spacing.m) {
                    segmentedToggle

                    if mode == .login {
                        LoginForm()
                    } else {
                        SignUpForm()
                    }
                }

                Spacer(minLength: Spacing.xl)
            }
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.vertical, Spacing.xl)
        }
        .background(PawlyColors.cream.ignoresSafeArea())
    }

    private var hero: some View {
        VStack(spacing: Spacing.s) {
            Image(systemName: "pawprint.fill")
                .font(.system(size: 56, weight: .semibold))
                .foregroundStyle(PawlyColors.forest)
            Text("Pawly")
                .font(PawlyFont.displayLarge)
                .foregroundStyle(PawlyColors.ink)
            Text("Sign in to keep your pet's world safe and synced.")
                .font(PawlyFont.bodyLarge)
                .foregroundStyle(PawlyColors.slate)
                .multilineTextAlignment(.center)
        }
        .padding(.top, Spacing.xxl)
    }

    private var segmentedToggle: some View {
        HStack(spacing: 0) {
            AuthModeButton(title: "Log In", isSelected: mode == .login) {
                withAnimation(Motion.micro) { mode = .login }
            }
            AuthModeButton(title: "Sign Up", isSelected: mode == .signup) {
                withAnimation(Motion.micro) { mode = .signup }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: Radius.button, style: .continuous)
                .fill(PawlyColors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.button, style: .continuous)
                .stroke(PawlyColors.sand, lineWidth: 1)
        )
    }
}

// MARK: - Login Form

private struct LoginForm: View {
    @EnvironmentObject private var authService: AuthService
    @State private var email = ""
    @State private var password = ""

    private var canSubmit: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty
        && password.count >= 6
    }

    var body: some View {
        VStack(spacing: Spacing.m) {
            PawlyTextField(label: "Email", text: $email, placeholder: "you@example.com", keyboard: .emailAddress, autocapitalization: .never)
            SecureFieldRow(label: "Password", text: $password, placeholder: "••••••")

            if let error = authService.authError {
                Text(error)
                    .font(PawlyFont.caption)
                    .foregroundStyle(PawlyColors.alert)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }

            Button {
                Task {
                    await authService.signIn(email: email, password: password)
                }
            } label: {
                HStack {
                    if authService.isLoading {
                        ProgressView()
                            .tint(.white)
                    }
                    Text("Log In")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.pawlyPrimary)
            .disabled(!canSubmit || authService.isLoading)
        }
    }
}

// MARK: - Sign Up Form

private struct SignUpForm: View {
    @EnvironmentObject private var authService: AuthService
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    private var canSubmit: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty
        && password.count >= 6
        && password == confirmPassword
    }

    var body: some View {
        VStack(spacing: Spacing.m) {
            PawlyTextField(label: "Email", text: $email, placeholder: "you@example.com", keyboard: .emailAddress, autocapitalization: .never)
            SecureFieldRow(label: "Password", text: $password, placeholder: "At least 6 characters")
            SecureFieldRow(label: "Confirm Password", text: $confirmPassword, placeholder: "Re-enter password")

            if let error = authService.authError {
                Text(error)
                    .font(PawlyFont.caption)
                    .foregroundStyle(PawlyColors.alert)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }

            Button {
                Task {
                    await authService.signUp(email: email, password: password)
                }
            } label: {
                HStack {
                    if authService.isLoading {
                        ProgressView()
                            .tint(.white)
                    }
                    Text("Create Account")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.pawlyPrimary)
            .disabled(!canSubmit || authService.isLoading)
        }
    }
}

// MARK: - Reusable components

private struct AuthModeButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(PawlyFont.headingMedium)
                .frame(maxWidth: .infinity, minHeight: Spacing.tapTargetMin)
                .foregroundStyle(isSelected ? .white : PawlyColors.ink)
                .background(
                    RoundedRectangle(cornerRadius: Radius.button, style: .continuous)
                        .fill(isSelected ? PawlyColors.forest : Color.clear)
                )
        }
        .buttonStyle(.plain)
    }
}

private struct SecureFieldRow: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(label)
                .font(PawlyFont.caption)
                .foregroundStyle(PawlyColors.slate)
            SecureField(placeholder, text: $text)
                .font(PawlyFont.bodyLarge)
                .foregroundStyle(PawlyColors.ink)
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
