import SwiftUI

// MARK: - AuthView

struct AuthView: View {
    @EnvironmentObject private var authService: AuthService
    @State private var mode: AuthMode = .login

    enum AuthMode { case login, signup }

    var body: some View {
        ZStack {
            // Warm cream background
            Color(hex: "#FFFBF5").ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // ── HEADER: Logo ──
                    Image("AppLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200)
                        .padding(.top, 24)

                    // ── FORM CARD ──
                    VStack(spacing: 0) {
                        if mode == .login {
                            LoginFormCard()
                                .transition(.asymmetric(
                                    insertion: .move(edge: .leading).combined(with: .opacity),
                                    removal: .move(edge: .trailing).combined(with: .opacity)
                                ))
                        } else {
                            SignUpFormCard()
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)

                    // ── FOOTER ──
                    VStack(spacing: 16) {
                        if mode == .login {
                            HStack(spacing: 4) {
                                Text("New to Paw n Furr?")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(Color(hex: "#6C757D"))
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { mode = .signup }
                                } label: {
                                    Text("Sign up")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(Color(hex: "#FF6B6B"))
                                }
                                .buttonStyle(.plain)
                            }
                        } else {
                            HStack(spacing: 4) {
                                Text("Already have an account?")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(Color(hex: "#6C757D"))
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { mode = .login }
                                } label: {
                                    Text("Log in")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(Color(hex: "#FF6B6B"))
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        // House illustration
                        VStack(spacing: 2) {
                            ZStack {
                                Image(systemName: "house.fill")
                                    .font(.system(size: 50))
                                    .foregroundStyle(Color(hex: "#FF8A8A").opacity(0.5))
                            }
                            // Pet bowl under house
                            HStack(spacing: 20) {
                                Ellipse()
                                    .fill(Color(hex: "#47C1B1"))
                                    .frame(width: 30, height: 12)
                                Ellipse()
                                    .fill(Color(hex: "#FF9A8B"))
                                    .frame(width: 30, height: 12)
                            }
                        }
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 40)
                }
            }
            .scrollIndicators(.hidden)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }

}

// MARK: - Login Form Card

private struct LoginFormCard: View {
    @EnvironmentObject private var authService: AuthService
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var showingForgotPassword = false

    private var canSubmit: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty && password.count >= 6
    }

    var body: some View {
        VStack(spacing: 0) {
            // Card top padding (below pets)
            Color.clear.frame(height: 40)

            VStack(spacing: 20) {
                // Header text
                VStack(spacing: 6) {
                    Text("Welcome Back")
                        .font(.system(size: 26, weight: .heavy))
                        .foregroundStyle(Color(hex: "#1A237E"))
                    Text("We've missed you and your furry friend!")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(Color(hex: "#6C757D"))
                        .multilineTextAlignment(.center)
                }

                // Email input
                AuthIconInput(
                    icon: "envelope",
                    iconColor: Color(hex: "#47C1B1"),
                    placeholder: "Email Address",
                    text: $email,
                    showPassword: .constant(false)
                )

                // Password input
                AuthIconInput(
                    icon: "lock",
                    iconColor: Color(hex: "#7B61FF"),
                    placeholder: "Password",
                    text: $password,
                    isSecure: true,
                    showPassword: $showPassword
                )

                // Forgot password
                HStack {
                    Spacer()
                    Button {
                        showingForgotPassword = true
                    } label: {
                        Text("Forgot Password?")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color(hex: "#47C1B1"))
                    }
                    .buttonStyle(.plain)
                    .sheet(isPresented: $showingForgotPassword) {
                        ForgotPasswordSheet(prefillEmail: email)
                            .environmentObject(authService)
                    }
                }

                // Error
                if let error = authService.authError {
                    AuthErrorBanner(message: error)
                }

                // Login button
                Button {
                    Task { await authService.signIn(email: email, password: password) }
                } label: {
                    HStack(spacing: 8) {
                        if authService.isLoading {
                            ProgressView().tint(.white).scaleEffect(0.8)
                        }
                        Image(systemName: "pawprint.fill")
                            .font(.system(size: 18))
                        Text("Login")
                            .font(.system(size: 17, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 55)
                }
                .buttonStyle(.plain)
                .background(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#5ED7C6"), Color(hex: "#47C1B1")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: Color(hex: "#47C1B1").opacity(0.4), radius: 12, x: 0, y: 6)
                )
                .disabled(!canSubmit || authService.isLoading)
                .opacity(canSubmit ? 1.0 : 0.6)

                // Divider
            }
            .padding(24)
        }
        .background(
            RoundedRectangle(cornerRadius: 35, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 20, x: 0, y: 10)
        )
    }
}

// MARK: - Sign Up Form Card

private struct SignUpFormCard: View {
    @EnvironmentObject private var authService: AuthService
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var agreeTerms = false

    private var canSubmit: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty
        && password.count >= 6
        && password == confirmPassword
        && agreeTerms
    }

    private var passwordStrength: AuthPasswordStrength {
        AuthPasswordStrength.evaluate(password)
    }

    private var passwordsMismatch: Bool {
        !confirmPassword.isEmpty && password != confirmPassword
    }

    var body: some View {
        VStack(spacing: 0) {
            Color.clear.frame(height: 40)

            VStack(spacing: 18) {
                VStack(spacing: 6) {
                    Text("Create Account")
                        .font(.system(size: 26, weight: .heavy))
                        .foregroundStyle(Color(hex: "#1A237E"))
                    Text("Join our pet-loving community!")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: "#6C757D"))
                        .multilineTextAlignment(.center)
                }

                AuthIconInput(
                    icon: "envelope",
                    iconColor: Color(hex: "#47C1B1"),
                    placeholder: "Email Address",
                    text: $email,
                    showPassword: .constant(false)
                )

                AuthIconInput(
                    icon: "lock",
                    iconColor: Color(hex: "#7B61FF"),
                    placeholder: "Password",
                    text: $password,
                    isSecure: true,
                    showPassword: $showPassword
                )

                if !password.isEmpty {
                    AuthStrengthBar(strength: passwordStrength)
                }

                AuthIconInput(
                    icon: "lock.fill",
                    iconColor: Color(hex: "#FF9A8B"),
                    placeholder: "Confirm Password",
                    text: $confirmPassword,
                    isSecure: true,
                    showPassword: $showPassword
                )

                if passwordsMismatch {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 11))
                        Text("Passwords don't match")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(Color(hex: "#DC2626"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Terms toggle
                Button {
                    agreeTerms.toggle()
                } label: {
                    HStack(spacing: 7) {
                        Image(systemName: agreeTerms ? "checkmark.square.fill" : "square")
                            .font(.system(size: 18))
                            .foregroundStyle(agreeTerms ? Color(hex: "#47C1B1") : Color(hex: "#A0A0A0"))
                        Text("I agree to Terms & Privacy Policy")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(hex: "#444444"))
                    }
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, alignment: .leading)

                if let error = authService.authError {
                    AuthErrorBanner(message: error)
                }

                // Sign up button
                Button {
                    Task { await authService.signUp(email: email, password: password) }
                } label: {
                    HStack(spacing: 8) {
                        if authService.isLoading {
                            ProgressView().tint(.white).scaleEffect(0.8)
                        }
                        Image(systemName: "pawprint.fill")
                            .font(.system(size: 18))
                        Text("Sign Up")
                            .font(.system(size: 17, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 55)
                }
                .buttonStyle(.plain)
                .background(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#5ED7C6"), Color(hex: "#47C1B1")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: Color(hex: "#47C1B1").opacity(0.4), radius: 12, x: 0, y: 6)
                )
                .disabled(!canSubmit || authService.isLoading)
                .opacity(canSubmit ? 1.0 : 0.6)

                // Divider
            }
            .padding(24)
        }
        .background(
            RoundedRectangle(cornerRadius: 35, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 20, x: 0, y: 10)
        )
    }
}

// MARK: - Icon Input Field

struct AuthIconInput: View {
    let icon: String
    let iconColor: Color
    var placeholder: String = ""
    @Binding var text: String
    var isSecure: Bool = false
    @Binding var showPassword: Bool
    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(iconColor)
                .frame(width: 22)

            Group {
                if isSecure && !showPassword {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .font(.system(size: 15))
            .foregroundStyle(Color(hex: "#333333"))
            .textInputAutocapitalization(.never)
            .keyboardType(.emailAddress)
            .autocorrectionDisabled()
            .focused($focused)

            if isSecure {
                Button {
                    showPassword.toggle()
                } label: {
                    Image(systemName: showPassword ? "eye.slash" : "eye")
                        .font(.system(size: 15))
                        .foregroundStyle(Color(hex: "#A0A0A0"))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(Color(hex: "#F8F9FA"))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .stroke(focused ? iconColor.opacity(0.5) : Color(hex: "#E9ECEF"), lineWidth: focused ? 1.5 : 1)
        )
        .animation(.easeOut(duration: 0.15), value: focused)
    }
}

// MARK: - Strength Bar

private enum AuthPasswordStrength {
    case weak, fair, good, strong

    static func evaluate(_ password: String) -> AuthPasswordStrength {
        var score = 0
        if password.count >= 8 { score += 1 }
        if password.rangeOfCharacter(from: .uppercaseLetters) != nil { score += 1 }
        if password.rangeOfCharacter(from: .decimalDigits) != nil { score += 1 }
        if password.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:'\",.<>?/")) != nil { score += 1 }
        switch score {
        case 0...1: return .weak
        case 2: return .fair
        case 3: return .good
        default: return .strong
        }
    }

    var color: Color {
        switch self {
        case .weak: return Color(hex: "#DC2626")
        case .fair: return Color(hex: "#F59E0B")
        case .good: return Color(hex: "#4CAF74")
        case .strong: return Color(hex: "#1A237E")
        }
    }

    var label: String {
        switch self {
        case .weak: return "Weak"
        case .fair: return "Fair"
        case .good: return "Good"
        case .strong: return "Strong"
        }
    }

    var fillWidth: CGFloat {
        switch self {
        case .weak: return 0.25
        case .fair: return 0.5
        case .good: return 0.75
        case .strong: return 1.0
        }
    }
}

private struct AuthStrengthBar: View {
    let strength: AuthPasswordStrength

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(hex: "#E9ECEF"))
                        .frame(height: 5)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(strength.color)
                        .frame(width: geo.size.width * strength.fillWidth, height: 5)
                        .animation(.spring(response: 0.3), value: strength)
                }
            }
            .frame(height: 5)
            Text(strength.label)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(strength.color)
        }
    }
}

// MARK: - Error Banner

struct AuthErrorBanner: View {
    let message: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 13))
            Text(message)
                .font(.system(size: 12, weight: .medium))
            Spacer()
        }
        .foregroundStyle(Color(hex: "#DC2626"))
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(hex: "#DC2626").opacity(0.08))
        )
    }
}

// MARK: - Forgot Password Sheet

private struct ForgotPasswordSheet: View {
    let prefillEmail: String
    @EnvironmentObject private var authService: AuthService
    @Environment(\.dismiss) private var dismiss

    @State private var email: String = ""
    @State private var isSent = false
    @State private var isSending = false
    @State private var errorMessage: String? = nil

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color(hex: "#47C1B1").opacity(0.12))
                        .frame(width: 72, height: 72)
                    Image(systemName: isSent ? "checkmark.circle.fill" : "lock.rotation")
                        .font(.system(size: 30))
                        .foregroundStyle(Color(hex: "#47C1B1"))
                }
                .padding(.top, 8)

                VStack(spacing: 8) {
                    Text(isSent ? "Check your inbox" : "Reset your password")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Color(hex: "#1A237E"))
                    Text(isSent
                         ? "We've sent a reset link to \(email). Check your email and follow the instructions."
                         : "Enter your email and we'll send you a link to reset your password.")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: "#6C757D"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }

                if !isSent {
                    AuthIconInput(
                        icon: "envelope",
                        iconColor: Color(hex: "#47C1B1"),
                        placeholder: "Email Address",
                        text: $email,
                        showPassword: .constant(false)
                    )

                    if let errorMessage {
                        AuthErrorBanner(message: errorMessage)
                    }

                    Button {
                        Task { await sendReset() }
                    } label: {
                        HStack(spacing: 8) {
                            if isSending { ProgressView().tint(.white).scaleEffect(0.8) }
                            Text("Send reset link")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: 26, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "#5ED7C6"), Color(hex: "#47C1B1")],
                                        startPoint: .leading, endPoint: .trailing
                                    )
                                )
                                .shadow(color: Color(hex: "#47C1B1").opacity(0.35), radius: 10, x: 0, y: 5)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(email.trimmingCharacters(in: .whitespaces).isEmpty || isSending)
                    .opacity(email.trimmingCharacters(in: .whitespaces).isEmpty ? 0.6 : 1)
                } else {
                    Button {
                        dismiss()
                    } label: {
                        Text("Back to login")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                RoundedRectangle(cornerRadius: 26, style: .continuous)
                                    .fill(Color(hex: "#47C1B1"))
                            )
                    }
                    .buttonStyle(.plain)
                }

                Spacer()
            }
            .padding(.horizontal, 24)
            .background(Color(hex: "#FAFAFA").ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color(hex: "#47C1B1"))
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .onAppear { email = prefillEmail }
    }

    private func sendReset() async {
        isSending = true
        errorMessage = nil
        let success = await authService.resetPassword(email: email.trimmingCharacters(in: .whitespaces))
        isSending = false
        if success {
            isSent = true
        } else {
            errorMessage = authService.authError ?? "Failed to send reset email. Please try again."
        }
    }
}

// MARK: - Previews

#Preview("Auth") {
    AuthView()
        .environmentObject(AuthService.shared)
}