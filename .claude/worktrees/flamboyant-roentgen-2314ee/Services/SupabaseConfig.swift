import Foundation
import Supabase

/// Supabase configuration and client singleton
enum SupabaseConfig {
    static let supabaseURL = URL(string: "https://xdcspqbwpdfgacojabyo.supabase.co")!
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhkY3NwcWJ3cGRmZ2Fjb2phYnlvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc1NjExNTgsImV4cCI6MjA5MzEzNzE1OH0.xhWDNqklQ66sXTXE1bmLZSSSeh5qP_CFcSzdEJ-FBhA"

    static let client = SupabaseClient(
        supabaseURL: supabaseURL,
        supabaseKey: supabaseAnonKey,
        options: SupabaseClientOptions(
            auth: SupabaseClientOptions.AuthOptions(
                emitLocalSessionAsInitialSession: true
            )
        )
    )
}
