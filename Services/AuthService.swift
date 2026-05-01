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

    private let client = SupabaseConfig.client

    private init() {
        Task {
            await restoreSession()
        }
    }

    // MARK: - Session

    /// Attempt to restore an existing session on cold launch.
    func restoreSession() async {
        isLoading = true
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

    // MARK: - Sign Out

    func signOut() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await client.auth.signOut()
            currentUser = nil
        } catch {
            authError = error.localizedDescription
        }
    }
}
