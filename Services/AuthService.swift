import Foundation
import Supabase

/// PRD — Supabase Auth wrapper. Handles email/password sign-up, sign-in,
/// sign-out, and session observation. Supabase persists the session in the
/// Keychain automatically.
@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var authError: String?
    @Published var isInPasswordRecovery = false

    private let client = SupabaseConfig.client

    private init() {
        Task { @MainActor in
            await restoreSession()
        }
        // Keep currentUser in sync with Supabase token refresh and sign-out events.
        // NOTE: For a password-recovery deep link Supabase emits .signedIn THEN
        // .passwordRecovery in the same stream.  We must NOT reset isInPasswordRecovery
        // inside .signedIn — let .passwordRecovery do it so the sheet always appears.
        Task { @MainActor in
            for await (event, session) in await client.auth.authStateChanges {
                switch event {
                case .signedIn:
                    currentUser = session?.user
                    // Do NOT touch isInPasswordRecovery here — .passwordRecovery follows
                    // immediately for recovery sessions and will set it to true.
                case .tokenRefreshed:
                    currentUser = session?.user
                case .userUpdated:
                    currentUser = session?.user
                    isInPasswordRecovery = false
                case .passwordRecovery:
                    currentUser = session?.user
                    isInPasswordRecovery = true
                case .signedOut:
                    currentUser = nil
                    isInPasswordRecovery = false
                default:
                    break
                }
            }
        }
    }

    // MARK: - Session

    /// Attempt to restore an existing session on cold launch.
    func restoreSession() async {
        isLoading = true
        authError = nil
        defer { isLoading = false }
        do {
            let session = try await client.auth.session
            currentUser = session.user
        } catch {
            currentUser = nil
        }
    }

    var isAuthenticated: Bool {
        currentUser != nil
    }

    var userId: UUID? {
        currentUser?.id
    }

    // MARK: - Sign Up

    func signUp(email: String, password: String) async -> Bool {
        isLoading = true
        authError = nil
        defer { isLoading = false }
        do {
            let response = try await client.auth.signUp(
                email: email,
                password: password
            )
            currentUser = response.user
            return true
        } catch {
            authError = error.localizedDescription
            return false
        }
    }

    // MARK: - Sign In

    func signIn(email: String, password: String) async -> Bool {
        isLoading = true
        authError = nil
        defer { isLoading = false }
        do {
            let session = try await client.auth.signIn(
                email: email,
                password: password
            )
            currentUser = session.user
            return true
        } catch {
            authError = error.localizedDescription
            return false
        }
    }

    // MARK: - Reset Password

    func resetPassword(email: String) async -> Bool {
        isLoading = true
        authError = nil
        defer { isLoading = false }
        do {
            try await client.auth.resetPasswordForEmail(
                email,
                redirectTo: URL(string: "https://www.pawnfurr.com/reset-password")
            )
            return true
        } catch {
            authError = error.localizedDescription
            return false
        }
    }

    /// Called after the user opens the recovery deep link and enters a new password.
    func setNewPassword(_ newPassword: String) async -> Bool {
        isLoading = true
        authError = nil
        defer { isLoading = false }
        do {
            let user = try await client.auth.update(user: UserAttributes(password: newPassword))
            currentUser = user
            return true
        } catch {
            authError = error.localizedDescription
            return false
        }
    }

    /// Handle Supabase deep-link (password recovery, magic link, etc.)
    ///
    /// Supabase PKCE flow: the email link lands on pawnfurr.com/reset-password which
    /// forwards `?code=` to the `pawnfurr://` scheme.  `session(from:)` exchanges the
    /// code for a session and fires `.passwordRecovery` in `authStateChanges`.
    ///
    /// Three failure modes we guard against:
    ///  1. PKCE code-verifier not in storage (app was killed before opening link)
    ///     → we fall back to treating it as an expired link and tell the user.
    ///  2. Code already redeemed or expired → same user-visible message.
    ///  3. Supabase events arrive before `authStateChanges` loop is listening
    ///     → we set `isInPasswordRecovery` ourselves after a successful exchange.
    func handleDeepLink(_ url: URL) {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let isRecoveryURL = components?.queryItems?.contains(where: { $0.name == "code" }) == true
            || url.fragment?.contains("type=recovery") == true

        Task {
            do {
                try await client.auth.session(from: url)
                // session(from:) succeeded — authStateChanges will emit .passwordRecovery.
                // As a safety net (race: authStateChanges loop not yet subscribed),
                // also set the flag here if this looks like a recovery URL.
                if isRecoveryURL {
                    isInPasswordRecovery = true
                }
            } catch {
                if isRecoveryURL {
                    // Tell the user what happened so they can request a new link.
                    authError = "This password reset link has expired or has already been used. Please request a new one."
                    // Still surface the password-recovery screen so the error is visible.
                    isInPasswordRecovery = true
                }
            }
        }
    }

    // MARK: - Sign Out

    func signOut() async {
        isLoading = true
        authError = nil
        defer { isLoading = false }
        do {
            try await client.auth.signOut()
            currentUser = nil
        } catch {
            authError = error.localizedDescription
        }
    }
}
