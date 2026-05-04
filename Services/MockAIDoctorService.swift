import Foundation

/// PRD §6.5 — AI Doctor triage response model. Codable so it can be
/// parsed from Groq JSON output.
struct TriageResponse: Hashable, Identifiable, Codable {
    enum Urgency: String, Codable {
        case watchAtHome = "watchAtHome"
        case vetWithin24h = "vetWithin24h"
        case vetNow = "vetNow"

        var displayValue: String {
            switch self {
            case .watchAtHome:   return "Watch at home"
            case .vetWithin24h:  return "Vet within 24 hours"
            case .vetNow:        return "Vet now"
            }
        }

        var colorHint: String {
            switch self {
            case .watchAtHome: return "sage"
            case .vetWithin24h: return "peach"
            case .vetNow: return "alert"
            }
        }
    }

    let id = UUID()
    let userPrompt: String
    let whatMightBeHappening: [String]
    let urgency: Urgency
    let whatYouCanDoNow: [String]
    let whenToEscalate: [String]
    let confidence: ConfidenceBadge.Level
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case whatMightBeHappening
        case urgency
        case whatYouCanDoNow
        case whenToEscalate
        case confidence
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(whatMightBeHappening, forKey: .whatMightBeHappening)
        try container.encode(urgency, forKey: .urgency)
        try container.encode(whatYouCanDoNow, forKey: .whatYouCanDoNow)
        try container.encode(whenToEscalate, forKey: .whenToEscalate)
        try container.encode(confidence, forKey: .confidence)
    }

    init(
        userPrompt: String,
        whatMightBeHappening: [String],
        urgency: Urgency,
        whatYouCanDoNow: [String],
        whenToEscalate: [String],
        confidence: ConfidenceBadge.Level,
        createdAt: Date = .now
    ) {
        self.userPrompt = userPrompt
        self.whatMightBeHappening = whatMightBeHappening
        self.urgency = urgency
        self.whatYouCanDoNow = whatYouCanDoNow
        self.whenToEscalate = whenToEscalate
        self.confidence = confidence
        self.createdAt = createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.whatMightBeHappening = try container.decode([String].self, forKey: .whatMightBeHappening)
        self.urgency = try container.decode(Urgency.self, forKey: .urgency)
        self.whatYouCanDoNow = try container.decode([String].self, forKey: .whatYouCanDoNow)
        self.whenToEscalate = try container.decode([String].self, forKey: .whenToEscalate)
        self.confidence = try container.decode(ConfidenceBadge.Level.self, forKey: .confidence)
        self.userPrompt = ""
        self.createdAt = .now
    }
}

// MARK: - Groq AI Service

/// Live Groq-powered AI Doctor. Falls back to keyword heuristics on network failure.
@MainActor
enum GroqService {
    struct ChatCompletionRequest: Codable {
        let model: String
        let messages: [Message]
        let temperature: Double
        let max_tokens: Int
        let response_format: ResponseFormat?

        struct Message: Codable {
            let role: String
            let content: String
        }

        struct ResponseFormat: Codable {
            let type: String
        }
    }

    struct ChatCompletionResponse: Codable {
        let choices: [Choice]

        struct Choice: Codable {
            let message: Message

            struct Message: Codable {
                let content: String
            }
        }
    }

    private static let systemPrompt = """
    You are Pawly's AI Doctor, a compassionate pet health triage assistant for pet owners in India and worldwide.

    Your job is to read the user's description of their pet's symptoms and return ONLY a JSON object with no markdown, no explanations outside the JSON, and no code fences.

    Required JSON format:
    {
      "whatMightBeHappening": ["Concise possibility 1", "Concise possibility 2"],
      "urgency": "watchAtHome" | "vetWithin24h" | "vetNow",
      "whatYouCanDoNow": ["Actionable step 1", "Actionable step 2", "Actionable step 3"],
      "whenToEscalate": ["Red flag 1", "Red flag 2"],
      "confidence": "low" | "medium" | "high"
    }

    Urgency rules:
    - "vetNow": blood, seizure, collapse, unconscious, can't breathe, hit by car, severe trauma, bloat, poison ingestion, continuous vomiting with blood.
    - "vetWithin24h": vomiting, diarrhea, not eating, lethargy, limping, eye discharge, ear infection signs.
    - "watchAtHome": mild itch, occasional sneeze, slight appetite change, minor scratch.

    Guidelines:
    - Be empathetic but never give false reassurance for serious symptoms.
    - Keep each string under 120 characters.
    - Provide 2-3 items per array.
    - Confidence reflects how well symptoms match known patterns.
    - Always suggest seeing a real vet for anything you are unsure about.
    """

    static func respond(to prompt: String, petName: String = "your pet") async -> TriageResponse {
        let personalizedPrompt = prompt + "\n\n(Pet name: \(petName))"

        let requestBody = ChatCompletionRequest(
            model: GroqConfig.model,
            messages: [
                .init(role: "system", content: systemPrompt),
                .init(role: "user", content: personalizedPrompt)
            ],
            temperature: 0.4,
            max_tokens: 512,
            response_format: .init(type: "json_object")
        )

        guard let httpBody = try? JSONEncoder().encode(requestBody) else {
            return fallbackResponse(for: prompt, petName: petName)
        }

        var request = URLRequest(url: GroqConfig.chatEndpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(GroqConfig.apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = httpBody

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse,
               !(200...299).contains(httpResponse.statusCode) {
                let body = String(data: data, encoding: .utf8) ?? ""
                print("Groq HTTP \(httpResponse.statusCode): \(body)")
                return fallbackResponse(for: prompt, petName: petName)
            }

            let completion = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
            guard let content = completion.choices.first?.message.content else {
                return fallbackResponse(for: prompt, petName: petName)
            }

            let cleaned = cleanJSON(content)
            guard let data = cleaned.data(using: String.Encoding.utf8) else {
                return fallbackResponse(for: prompt, petName: petName)
            }
            var triage = try JSONDecoder().decode(TriageResponse.self, from: data)
            triage = TriageResponse(
                userPrompt: prompt,
                whatMightBeHappening: triage.whatMightBeHappening,
                urgency: triage.urgency,
                whatYouCanDoNow: triage.whatYouCanDoNow,
                whenToEscalate: triage.whenToEscalate,
                confidence: triage.confidence,
                createdAt: .now
            )
            return triage

        } catch {
            print("Groq error: \(error)")
            return fallbackResponse(for: prompt, petName: petName)
        }
    }

    // MARK: - Helpers

    private static func cleanJSON(_ raw: String) -> String {
        var cleaned = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("```json") {
            cleaned = String(cleaned.dropFirst(7))
        }
        if cleaned.hasPrefix("```") {
            cleaned = String(cleaned.dropFirst(3))
        }
        if cleaned.hasSuffix("```") {
            cleaned = String(cleaned.dropLast(3))
        }
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Offline fallback using the original keyword heuristics.
    private static func fallbackResponse(for prompt: String, petName: String) -> TriageResponse {
        let lower = prompt.lowercased()

        if lower.contains("blood") || lower.contains("seizure") || lower.contains("collapse")
            || lower.contains("unconscious") || lower.contains("can't breathe")
            || lower.contains("hit by") {
            return TriageResponse(
                userPrompt: prompt,
                whatMightBeHappening: [
                    "This sounds like a potential emergency that needs a vet immediately.",
                    "Possible causes range from trauma to acute illness."
                ],
                urgency: .vetNow,
                whatYouCanDoNow: [
                    "Keep \(petName) calm, warm, and still.",
                    "Do not give any food, water, or medication.",
                    "Head to your nearest 24/7 vet clinic."
                ],
                whenToEscalate: [
                    "Any time. This is not a watch-at-home situation."
                ],
                confidence: .high
            )
        }

        if lower.contains("vomit") || lower.contains("diarrhea") || lower.contains("loose stool") {
            return TriageResponse(
                userPrompt: prompt,
                whatMightBeHappening: [
                    "Dietary upset from something new or spoiled.",
                    "Mild gastrointestinal infection or parasites.",
                    "Occasionally, reaction to a new medication."
                ],
                urgency: .vetWithin24h,
                whatYouCanDoNow: [
                    "Withhold food for 6–8 hours but keep water available.",
                    "Offer a small bland meal (plain boiled rice + chicken) afterwards.",
                    "Note frequency, color, and any blood in the stool."
                ],
                whenToEscalate: [
                    "Vomiting or diarrhea for more than 24 hours.",
                    "Blood in stool or vomit, lethargy, or refusal to drink water."
                ],
                confidence: .medium
            )
        }

        if lower.contains("itch") || lower.contains("scratch") || lower.contains("skin") {
            return TriageResponse(
                userPrompt: prompt,
                whatMightBeHappening: [
                    "Flea or tick activity — very common in Indian climates.",
                    "Food or environmental allergy.",
                    "Dry skin from frequent bathing."
                ],
                urgency: .watchAtHome,
                whatYouCanDoNow: [
                    "Check behind ears, armpits, and belly for fleas or ticks.",
                    "Avoid bathing for a few days; try an oatmeal pet shampoo if needed.",
                    "Keep bedding clean and watch for hot spots."
                ],
                whenToEscalate: [
                    "Open sores, pus, or strong smell from the skin.",
                    "Itch continues past 3–4 days despite flea control."
                ],
                confidence: .medium
            )
        }

        if lower.contains("lethargy") || lower.contains("tired") || lower.contains("not eating") {
            return TriageResponse(
                userPrompt: prompt,
                whatMightBeHappening: [
                    "Mild viral infection or heat fatigue.",
                    "Stress from household changes or travel.",
                    "Side effect of a recently started medication."
                ],
                urgency: .vetWithin24h,
                whatYouCanDoNow: [
                    "Check temperature by ear — hot and dry is a warning sign.",
                    "Offer plain water and a small portion of favorite food.",
                    "Let \(petName) rest in a cool, quiet room."
                ],
                whenToEscalate: [
                    "No food or water for more than 24 hours.",
                    "Pale gums, heavy panting, or unsteady walking."
                ],
                confidence: .medium
            )
        }

        return TriageResponse(
            userPrompt: prompt,
            whatMightBeHappening: [
                "I couldn't match this to a common pattern with confidence.",
                "Symptoms like this often have several mild causes, but some do need a vet."
            ],
            urgency: .watchAtHome,
            whatYouCanDoNow: [
                "Note exactly when symptoms started and what changed recently.",
                "Watch for changes in appetite, energy, or toileting over the next few hours.",
                "Take a short video if the symptom is visual — it helps your vet."
            ],
            whenToEscalate: [
                "Any worsening, or no improvement within 24 hours.",
                "Loss of appetite, vomiting, or visible discomfort."
            ],
            confidence: .low
        )
    }
}
