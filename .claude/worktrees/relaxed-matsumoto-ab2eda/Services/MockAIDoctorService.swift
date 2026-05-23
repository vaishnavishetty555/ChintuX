import Foundation

/// PRD §6.5 — AI Doctor triage response. The AI returns free-text vet-style responses.
struct TriageResponse: Hashable, Identifiable, Codable {
    enum Urgency: String, Codable {
        case watchAtHome = "watchAtHome"
        case vetWithin24h = "vetWithin24h"
        case vetNow = "vetNow"

        var displayValue: String {
            switch self {
            case .watchAtHome:   return "Monitor at home"
            case .vetWithin24h:  return "See vet within 24h"
            case .vetNow:        return "See vet now"
            }
        }
    }

    let id = UUID()
    let userPrompt: String
    let freeText: String
    let urgency: Urgency
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case userPrompt, freeText, urgency, createdAt
    }

    init(userPrompt: String, freeText: String, urgency: Urgency, createdAt: Date = .now) {
        self.userPrompt = userPrompt
        self.freeText = freeText
        self.urgency = urgency
        self.createdAt = createdAt
    }

    // Codable conformance
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.userPrompt = try container.decodeIfPresent(String.self, forKey: .userPrompt) ?? ""
        self.freeText = try container.decode(String.self, forKey: .freeText)
        self.urgency = try container.decode(Urgency.self, forKey: .urgency)
        self.createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? .now
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userPrompt, forKey: .userPrompt)
        try container.encode(freeText, forKey: .freeText)
        try container.encode(urgency, forKey: .urgency)
        try container.encode(createdAt, forKey: .createdAt)
    }

    // Computed helpers for backward compat
    var whatMightBeHappening: [String] { diagnosisFromFreeText }
    var whatYouCanDoNow: [String] { recommendationsFromFreeText }
    var whenToEscalate: [String] { escalationFromFreeText }
    var confidence: ConfidenceBadge.Level { .medium }

    private var diagnosisFromFreeText: [String] {
        freeText.components(separatedBy: "\n")
            .filter { $0.contains("•") || $0.contains("-") || $0.contains(":") }
            .filter { $0.lowercased().contains("possibl") || $0.lowercased().contains("may") || $0.lowercased().contains("could") || $0.lowercased().contains("likely") }
            .prefix(3)
            .map { $0.trimmingCharacters(in: .whitespaces) }
    }

    private var recommendationsFromFreeText: [String] {
        freeText.components(separatedBy: "\n")
            .filter { $0.contains("•") || $0.contains("-") }
            .filter { $0.lowercased().contains("do ") || $0.lowercased().contains("give") || $0.lowercased().contains("try") || $0.lowercased().contains("offer") || $0.lowercased().contains("ensure") || $0.lowercased().contains("keep") }
            .prefix(4)
            .map { $0.trimmingCharacters(in: .whitespaces) }
    }

    private var escalationFromFreeText: [String] {
        freeText.components(separatedBy: "\n")
            .filter { $0.lowercased().contains("seek") || $0.lowercased().contains("vet") || $0.lowercased().contains("emergency") || $0.lowercased().contains("red flag") || $0.lowercased().contains("urgent") || $0.lowercased().contains("worsen") || $0.lowercased().contains("contact") }
            .prefix(3)
            .map { $0.trimmingCharacters(in: .whitespaces) }
    }
}

// MARK: - Groq AI Service

/// Senior vet-style AI Doctor with free-text consultation responses.
@MainActor
enum GroqService {
    struct ChatCompletionRequest: Codable {
        let model: String
        let messages: [Message]
        let temperature: Double
        let max_tokens: Int

        struct Message: Codable {
            let role: String
            let content: String
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
You are Dr. Ruff, a senior veterinary consultant with 20+ years of clinical experience. You are warm, clear, and authoritative. You speak like a trusted family vet — direct, confident, and human — not a textbook or a chatbot.

Your role is to provide initial guidance for pet health concerns. You do NOT prescribe specific medications, but you CAN suggest supportive care measures (e.g., oral rehydration, bland diet, rest).

Format your response EXACTLY like this — each section on a new line, starting with a bold header in **text** format, followed by a • bullet list:

**What I'm considering:**
• [Possible cause 1]
• [Possible cause 2]
• [Possible cause 3]

**What to do right now:**
• [Actionable step 1]
• [Actionable step 2]
• [Actionable step 3]

**When to seek a vet:**
• [Specific red flag 1]
• [Specific red flag 2]

**My urgency assessment:** [SEEK_VET_NOW | SEE_VET_SOON | MONITOR_HOME]

---

Urgency guidelines:
- SEEK_VET_NOW: Blood, collapse, seizure, not breathing, hit by car, bloat, severe trauma, suspected poisoning, continuous bleeding, unable to stand.
- SEE_VET_SOON: Vomiting, diarrhea, lethargy, not eating >24h, limping, breathing changes, eye/ear discharge, suspected fracture.
- MONITOR_HOME: Mild itching, occasional sneeze, slight appetite change, minor scratch, first-day behavior change.

Rules:
- Never say "I'm not a vet" — you ARE acting as a vet consultant.
- Never recommend specific drug names (e.g., no "give Metronidazole") — just say what category of care.
- Be specific. "Vomiting twice after eating" is different from "vomiting blood for 6 hours." Adjust guidance accordingly.
- Keep it concise — 3 bullets per section maximum.
- Be empathetic and calm. Pet owners are worried.
- If you genuinely cannot make a reasonable assessment, say "Based on what you've shared, I'd recommend seeing a vet for a proper examination."
- Always add a final line: "This is AI-assisted guidance and not a substitute for a physical vet examination."
"""

    static func respond(
        to prompt: String,
        petName: String = "your pet",
        history: [(role: String, content: String)] = []
    ) async -> TriageResponse {
        var apiMessages: [ChatCompletionRequest.Message] = [
            .init(role: "system", content: systemPrompt)
        ]

        for (role, content) in history {
            apiMessages.append(.init(role: role, content: content))
        }

        let userMessage = history.isEmpty
            ? "\(prompt)\n\nNote: The pet's name is \(petName)."
            : prompt
        apiMessages.append(.init(role: "user", content: userMessage))

        let requestBody = ChatCompletionRequest(
            model: GroqConfig.model,
            messages: apiMessages,
            temperature: 0.5,
            max_tokens: 700
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

            let urgency = parseUrgency(from: content)
            return TriageResponse(
                userPrompt: prompt,
                freeText: content,
                urgency: urgency,
                createdAt: .now
            )

        } catch {
            print("Groq error: \(error)")
            return fallbackResponse(for: prompt, petName: petName)
        }
    }

    // MARK: - Helpers

    private static func parseUrgency(from text: String) -> TriageResponse.Urgency {
        let upper = text.uppercased()
        if upper.contains("SEEK_VET_NOW") { return .vetNow }
        if upper.contains("SEE_VET_SOON") { return .vetWithin24h }
        return .watchAtHome
    }

    /// Offline keyword-based fallback.
    private static func fallbackResponse(for prompt: String, petName: String) -> TriageResponse {
        let lower = prompt.lowercased()

        if lower.contains("blood") || lower.contains("seizure") || lower.contains("collapse")
            || lower.contains("unconscious") || lower.contains("can't breathe")
            || lower.contains("can't breathe") || lower.contains("not breathing") {
            return TriageResponse(
                userPrompt: prompt,
                freeText: """
**What I'm considering:**
• This sounds like a potential medical emergency requiring immediate attention.

**What to do right now:**
• Keep \(petName) calm, warm, and as still as possible.
• Do not give any food, water, or medication by mouth.
• Head to your nearest veterinary emergency clinic immediately.

**When to seek a vet:**
• This is an emergency — a vet visit is needed right now.

**My urgency assessment:** SEEK_VET_NOW
""",
                urgency: .vetNow
            )
        }

        if lower.contains("vomit") || lower.contains("diarrhea") || lower.contains("loose stool") {
            return TriageResponse(
                userPrompt: prompt,
                freeText: """
**What I'm considering:**
• Dietary upset — something new, spoiled, or a sudden diet change.
• Mild gastrointestinal irritation or sensitivity.
• Occasionally a reaction to a new treat or food item.

**What to do right now:**
• Withhold food for 6–8 hours but keep fresh water available at all times.
• After the fasting period, offer small amounts of plain boiled rice with plain boiled chicken.
• Note the frequency, colour, and any blood or mucus in the vomit or stool.

**When to seek a vet:**
• Vomiting or diarrhea persisting beyond 24 hours.
• Blood in vomit or stool, extreme lethargy, or refusal to drink water.
• \(petName) becomes unresponsive or shows signs of pain.

**My urgency assessment:** SEE_VET_SOON
""",
                urgency: .vetWithin24h
            )
        }

        if lower.contains("itch") || lower.contains("scratch") || lower.contains("skin") || lower.contains("rash") {
            return TriageResponse(
                userPrompt: prompt,
                freeText: """
**What I'm considering:**
• Flea or tick activity — very common, especially in warm climates.
• Food or environmental allergy — a recent diet change or new product could be the trigger.
• Dry skin from over-bathing or low humidity.

**What to do right now:**
• Check behind the ears, under the armpits, and around the belly for fleas, ticks, or hot spots.
• Avoid bathing \(petName) for a few days. Use an oatmeal-based pet shampoo if essential.
• Keep bedding clean and wash in hot water to reduce allergens.

**When to seek a vet:**
• Open sores, pus, discharge, or a strong odour from the skin.
• Itching that doesn't improve within 3–4 days of basic care.
• Hair loss or red, inflamed patches spreading to other areas.

**My urgency assessment:** MONITOR_HOME
""",
                urgency: .watchAtHome
            )
        }

        if lower.contains("letharg") || lower.contains("tired") || lower.contains("not eating")
            || lower.contains("not eating") || lower.contains("not eating") {
            return TriageResponse(
                userPrompt: prompt,
                freeText: """
**What I'm considering:**
• A mild viral or seasonal illness — common in pets, especially in changing weather.
• Heat fatigue or stress from a recent change in environment or routine.
• A possible side effect from any recently started medication or supplement.

**What to do right now:**
• Check \(petName)'s gums — they should be pink and moist, not pale or dry.
• Offer plain water first. Then try a small portion of their favourite food.
• Let \(petName) rest in a cool, quiet, well-ventilated space.

**When to seek a vet:**
• No food or water intake for more than 24 hours.
• Pale gums, heavy panting, difficulty breathing, or stumbling while walking.
• This condition persists into the next day without any improvement.

**My urgency assessment:** SEE_VET_SOON
""",
                urgency: .vetWithin24h
            )
        }

        if lower.contains("limping") || lower.contains("limb") || lower.contains("leg") || lower.contains("paw")
            || lower.contains("can't walk") {
            return TriageResponse(
                userPrompt: prompt,
                freeText: """
**What I'm considering:**
• A soft tissue injury such as a sprain or muscle strain.
• A hairline fracture or bone injury, especially if there was a recent fall or jump.
• Joint pain from arthritis or an underlying orthopaedic condition.

**What to do right now:**
• Limit \(petName)'s movement. Confine to a small room or crate to prevent worsening.
• Do not massage or apply heat to a swollen limb.
• If there is an open wound, clean it gently with saline or clean water.

**When to seek a vet:**
• The limp doesn't improve within 24–48 hours of rest.
• Significant swelling, inability to bear any weight on the limb, or visible deformity.
• \(petName) yelps in pain when the area is touched.

**My urgency assessment:** SEE_VET_SOON
""",
                urgency: .vetWithin24h
            )
        }

        return TriageResponse(
            userPrompt: prompt,
            freeText: """
**What I'm considering:**
• Based on what you've described, this could have several causes. A physical examination would help narrow things down.

**What to do right now:**
• Note the exact time this started and what \(petName) was doing just before.
• Watch for any changes in appetite, energy, toilet habits, or behaviour.
• Take a short video if the symptom is visible — this will be very helpful for your vet.

**When to seek a vet:**
• Any worsening of symptoms, new signs appearing, or no improvement within 24 hours.
• If \(petName) stops eating entirely or shows signs of significant discomfort.

**My urgency assessment:** MONITOR_HOME

This is AI-assisted guidance and not a substitute for a physical vet examination.
""",
            urgency: .watchAtHome
        )
    }
}