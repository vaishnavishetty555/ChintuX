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
        // Keep currentUser in sync with Supabase token refresh and sign-out events
        Task { @MainActor in
            for await (event, session) in await client.auth.authStateChanges {
                switch event {
                case .signedIn, .tokenRefreshed, .userUpdated:
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
    func handleDeepLink(_ url: URL) {
        Task {
            try? await client.auth.session(from: url)
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
