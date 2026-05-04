import Foundation

/// Groq API configuration.
/// ⚠️  SECURITY: The API key must NOT be committed to version control.
/// Add your key locally after cloning. In production, use a backend proxy
/// or the iOS Keychain.
enum GroqConfig {
    static let apiKey = "YOUR_GROQ_API_KEY"
    static let baseURL = URL(string: "https://api.groq.com/openai/v1")!
    static let chatEndpoint = baseURL.appendingPathComponent("chat/completions")

    /// Default fast model on Groq.
    static let model = "llama-3.3-70b-versatile"
}
