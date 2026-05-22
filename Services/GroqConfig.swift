import Foundation

/// Groq API configuration.
///
/// HOW TO ADD YOUR API KEY (pick one method):
///
/// METHOD 1 — Paste directly here (easiest for personal/dev builds):
///   Set `hardcodedKey` below to your full Groq key (starts with gsk_...)
///
/// METHOD 2 — Info.plist (recommended for team/release builds):
///   Add a key "GROQ_API_KEY" with your key as the value in Info.plist
///
/// METHOD 3 — Xcode scheme environment variable:
///   Product → Scheme → Edit Scheme → Run → Arguments → Environment Variables
///   Add GROQ_API_KEY = gsk_xxxx...
///
/// Get a free key at: https://console.groq.com → API Keys → Create key
///
enum GroqConfig {

    // ── METHOD 1: paste your key here ──────────────────────────────────────
    private static let hardcodedKey = ""   // ← add your gsk_... key here locally
    // ───────────────────────────────────────────────────────────────────────

    static let apiKey: String = {
        // 1. Hardcoded (fastest for dev)
        if !hardcodedKey.isEmpty { return hardcodedKey }
        // 2. Info.plist
        if let plistKey = Bundle.main.object(forInfoDictionaryKey: "GROQ_API_KEY") as? String,
           !plistKey.isEmpty { return plistKey }
        // 3. Xcode scheme / shell environment
        let envKey = ProcessInfo.processInfo.environment["GROQ_API_KEY"] ?? ""
        return envKey
    }()

    static var isConfigured: Bool { !apiKey.isEmpty }

    static let baseURL      = URL(string: "https://api.groq.com/openai/v1")!
    static let chatEndpoint = baseURL.appendingPathComponent("chat/completions")
    static let model        = "llama-3.3-70b-versatile"
}
