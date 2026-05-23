import Foundation

/// Groq API configuration.
///
/// HOW TO SET YOUR API KEY:
/// 1. Go to https://console.groq.com → API Keys → Create key
/// 2. Copy the full key (starts with gsk_xxxx...)
/// 3. Set it as an environment variable GROQ_API_KEY in your Xcode scheme
///    or in your shell before running the app.
/// 4. Never commit a real key to version control.
///
enum GroqConfig {

    static let apiKey: String = {
        ProcessInfo.processInfo.environment["GROQ_API_KEY"] ?? ""
    }()

    static let baseURL      = URL(string: "https://api.groq.com/openai/v1")!
    static let chatEndpoint = baseURL.appendingPathComponent("chat/completions")
    static let model        = "llama-3.3-70b-versatile"
}
