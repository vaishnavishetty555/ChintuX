import SwiftUI

// MARK: - AuthView

struct AuthView: View {
    @EnvironmentObject private var authService: AuthService
    @State private var mode: AuthMode = .login

    enum AuthMode { case login, signup }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {

                // ── Full-bleed background illustration ──
                // Extra height + upward offset reveals the cat/bottom pets
                // that would otherwise sit behind the glass card.
                Image("LoginBG")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height + 100)
                    .offset(y: -50)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .ignoresSafeArea()

                // ── Logo + Card stack, bottom-anchored ──
                // Logo floats centered above the glass card; card is shorter without it.
                VStack(spacing: 0) {

                    // Logo — outside the card, centered in the VStack
                    Image("AppLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 118)
                        .padding(.bottom, 38)

                    // ── Glass card ──
                    VStack(spacing: 0) {

                        // Mode title
                        VStack(spacing: 4) {
                            Text(mode == .login ? "Welcome Back" : "Create Account")
                                .font(.system(size: 26, weight: .heavy))
                                .foregroundStyle(Color(hex: "#1A237E"))
                                .animation(nil, value: mode)
                            Text(mode == .login
                                 ? "We've missed you and your furry friend!"
                                 : "Join our pet-loving community!")
                                .font(.system(size: 13))
                                .foregroundStyle(Color(hex: "#6C757D"))
                                .multilineTextAlignment(.center)
                                .animation(nil, value: mode)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 22)
                        .padding(.bottom, 16)
                        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: mode)

                        // Scrollable form — capped so it never bloats into blank space
                        ScrollView(.vertical, showsIndicators: false) {
                            Group {
                                if mode == .login {
                                    LoginFormContent()
                                        .transition(.asymmetric(
                                            insertion: .move(edge: .leading).combined(with: .opacity),
                                            removal:   .move(edge: .trailing).combined(with: .opacity)
                                        ))
                                } else {
                                    SignUpFormContent()
                                        .transition(.asymmetric(
                                            insertion: .move(edge: .trailing).combined(with: .opacity),
                                            removal:   .move(edge: .leading).combined(with: .opacity)
                                        ))
                                }
                            }
                            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: mode)
                        }
                        .frame(maxHeight: max(geo.size.height * 0.31, 248))

                        // Mode toggle footer
                        HStack(spacing: 4) {
                            if mode == .login {
                                Text("New to Paw n Furr?")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(Color(hex: "#555555"))
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { mode = .signup }
                                } label: {
                                    Text("Sign up")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(Color(hex: "#FF6B6B"))
                                }
                                .buttonStyle(.plain)
                            } else {
                                Text("Already have an account?")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(Color(hex: "#555555"))
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
                        .padding(.top, 10)
                        .padding(.bottom, 38)
                    }
                    .frame(maxWidth: .infinity)
                    // ── Glassmorphism ──
                    .background(
                        ZStack {
                            Color.clear.background(.ultraThinMaterial)
                            Color.white.opacity(0.52)
                        }
                        .ignoresSafeArea(edges: .bottom)
                    )
                    .cornerRadius(36)
                    .overlay(
                        RoundedRectangle(cornerRadius: 36, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.85), Color.white.opacity(0.25)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: .black.opacity(0.12), radius: 28, x: 0, y: -8)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .ignoresSafeArea()
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

// MARK: - Login Form Content

private struct LoginFormContent: View {
    @EnvironmentObject private var authService: AuthService
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var showingForgotPassword = false

    private var canSubmit: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty && password.count >= 6
    }

    var body: some View {
        VStack(spacing: 14) {
            // Email
            AuthIconInput(
                icon: "envelope",
                iconColor: Color(hex: "#47C1B1"),
                placeholder: "Email Address",
                text: $email,
                showPassword: .constant(false)
            )

            // Password
            AuthIconInput(
                icon: "lock",
                iconColor: Color(hex: "#7B61FF"),
                placeholder: "Password",
                text: $password,
                isSecure: true,
                showPassword: $showPassword
            )

            // Forgot password link
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

            // Error banner
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
                        .font(.system(size: 17))
                    Text("Login")
                        .font(.system(size: 17, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
            }
            .buttonStyle(.plain)
            .background(
                RoundedRectangle(cornerRadius: 27, style: .continuous)
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
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 10)
    }
}

// MARK: - Sign Up Form Content

private struct SignUpFormContent: View {
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
        VStack(spacing: 14) {
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

            // Error banner
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
                        .font(.system(size: 17))
                    Text("Sign Up")
                        .font(.system(size: 17, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
            }
            .buttonStyle(.plain)
            .background(
                RoundedRectangle(cornerRadius: 27, style: .continuous)
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
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 10)
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
                .font(.system(size: 17))
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
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: "#A0A0A0"))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                // Frosted white — sits cleanly on the glass panel
                .fill(Color.white.opacity(0.72))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(
                    focused ? iconColor.opacity(0.55) : Color.white.opacity(0.9),
                    lineWidth: focused ? 1.5 : 1
                )
        )
        .animation(.easeOut(duration: 0.15), value: focused)
    }
}

// MARK: - Password Strength Bar

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
        case 2:     return .fair
        case 3:     return .good
        default:    return .strong
        }
    }

    var color: Color {
        switch self {
        case .weak:   return Color(hex: "#DC2626")
        case .fair:   return Color(hex: "#F59E0B")
        case .good:   return Color(hex: "#4CAF74")
        case .strong: return Color(hex: "#1A237E")
        }
    }
    var label: String {
        switch self {
        case .weak:   return "Weak"
        case .fair:   return "Fair"
        case .good:   return "Good"
        case .strong: return "Strong"
        }
    }
    var fillWidth: CGFloat {
        switch self {
        case .weak:   return 0.25
        case .fair:   return 0.5
        case .good:   return 0.75
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

// MARK: - Forgot Password Sheet (OTP-based flow)

private struct ForgotPasswordSheet: View {
    let prefillEmail: String
    @EnvironmentObject private var authService: AuthService
    @Environment(\.dismiss) private var dismiss

    @State private var email: String = ""
    @State private var otpCode: String = ""
    @State private var isCodeSent = false
    @State private var isSending = false
    @State private var isVerifying = false
    @State private var errorMessage: String? = nil
    @State private var showSetNewPassword = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "#47C1B1").opacity(0.12))
                        .frame(width: 72, height: 72)
                    Image(systemName: isCodeSent ? "envelope.badge.shield.half.filled" : "lock.rotation")
                        .font(.system(size: 30))
                        .foregroundStyle(Color(hex: "#47C1B1"))
                }
                .padding(.top, 8)

                VStack(spacing: 8) {
                    Text(isCodeSent ? "Enter verification code" : "Reset your password")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Color(hex: "#1A237E"))
                    Text(isCodeSent
                         ? "We've sent an 8-digit code to \(email). Enter it below to continue."
                         : "Enter your email and we'll send you a verification code to reset your password.")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: "#6C757D"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }

                if !isCodeSent {
                    // Step 1: Enter email
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
                        Task { await sendOTP() }
                    } label: {
                        HStack(spacing: 8) {
                            if isSending { ProgressView().tint(.white).scaleEffect(0.8) }
                            Text("Send code")
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
                    // Step 2: Enter OTP code
                    VStack(spacing: 16) {
                        // OTP Input field
                        HStack {
                            Image(systemName: "number")
                                .font(.system(size: 17))
                                .foregroundStyle(Color(hex: "#47C1B1"))
                                .frame(width: 22)

                            TextField("Enter 8-digit code", text: $otpCode)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(Color(hex: "#333333"))
                                .keyboardType(.numberPad)
                                .textContentType(.oneTimeCode)
                                .multilineTextAlignment(.center)
                                .onChange(of: otpCode) { oldValue, newValue in
                                    // Limit to 8 digits
                                    let filtered = newValue.filter { $0.isNumber }
                                    if filtered.count > 8 {
                                        otpCode = String(filtered.prefix(8))
                                    } else if filtered != newValue {
                                        otpCode = filtered
                                    }
                                }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 13)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.white.opacity(0.72))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color(hex: "#47C1B1").opacity(0.55), lineWidth: 1.5)
                        )

                        if let errorMessage {
                            AuthErrorBanner(message: errorMessage)
                        }

                        Button {
                            Task { await verifyOTP() }
                        } label: {
                            HStack(spacing: 8) {
                                if isVerifying { ProgressView().tint(.white).scaleEffect(0.8) }
                                Text("Verify & Continue")
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
                        .disabled(otpCode.count != 8 || isVerifying)
                        .opacity(otpCode.count == 8 ? 1.0 : 0.6)

                        // Resend code button
                        Button {
                            Task { await sendOTP() }
                        } label: {
                            HStack(spacing: 4) {
                                if isSending {
                                    ProgressView()
                                        .tint(Color(hex: "#47C1B1"))
                                        .scaleEffect(0.7)
                                }
                                Text("Didn't receive it? Resend")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundStyle(Color(hex: "#47C1B1"))
                        }
                        .buttonStyle(.plain)
                        .disabled(isSending)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 24)
            .background(Color(hex: "#FAFAFA").ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        authService.cancelPasswordRecovery()
                        dismiss()
                    }
                        .foregroundStyle(Color(hex: "#47C1B1"))
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .onAppear { email = prefillEmail }
        .sheet(isPresented: $showSetNewPassword) {
            SetNewPasswordView()
                .environmentObject(authService)
        }
    }

    private func sendOTP() async {
        isSending = true
        errorMessage = nil
        let success = await authService.sendPasswordResetOTP(email: email.trimmingCharacters(in: .whitespaces))
        isSending = false
        if success {
            isCodeSent = true
        } else {
            errorMessage = authService.authError ?? "Failed to send code. Please try again."
        }
    }

    private func verifyOTP() async {
        isVerifying = true
        errorMessage = nil
        let success = await authService.verifyPasswordResetOTP(
            email: email.trimmingCharacters(in: .whitespaces),
            token: otpCode.trimmingCharacters(in: .whitespaces)
        )
        isVerifying = false
        if success {
            dismiss()
            // Small delay to let the sheet dismiss before showing password reset
            try? await Task.sleep(for: .milliseconds(300))
            await MainActor.run {
                showSetNewPassword = true
            }
        } else {
            errorMessage = authService.authError ?? "Invalid code. Please try again."
        }
    }
}

// MARK: - Previews

#Preview("Auth") {
    AuthView()
        .environmentObject(AuthService.shared)
}
