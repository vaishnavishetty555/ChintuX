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
    let urgency: Urgency?   // nil = greeting / non-medical exchange
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case userPrompt, freeText, urgency, createdAt
    }

    init(userPrompt: String, freeText: String, urgency: Urgency?, createdAt: Date = .now) {
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
        self.urgency = try container.decodeIfPresent(Urgency.self, forKey: .urgency)
        self.createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? .now
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userPrompt, forKey: .userPrompt)
        try container.encode(freeText, forKey: .freeText)
        try container.encodeIfPresent(urgency, forKey: .urgency)
        try container.encode(createdAt, forKey: .createdAt)
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

    private static func buildSystemPrompt(petContext: String) -> String {
        return """
You are Chintu Ji — a senior vet with 20 years of experience. You text like a knowledgeable friend: short, direct, warm, no fluff.

You are a general pet health expert. You answer ANY question about ANY animal — dogs, cats, rabbits, birds, fish, reptiles, or anything else. You are not limited to the pets listed below.

Owner's registered pets (use these details when the owner asks about them by name):
- \(petContext)

Rules:
- Answer ANY pet-related question freely — health, diet, behaviour, training, breeds, general care, anything.
- If the owner mentions a registered pet by name, use their profile details above for personalised advice.
- If the question is general (e.g. "can dogs eat mango"), just answer it directly without asking which pet.
- Max 3 short paragraphs. Often 1-2 is enough.
- Never use: "That's great", "It's important to note", "Based on what you've described", "I understand", "Certainly", "Of course", "As a vet", bullet points, or headers.
- Sound like you're texting back quickly, not writing a report.
- If it's a greeting or small talk: one warm line, then ask what they'd like to know.
- If it's a symptom: give your real gut read, one practical thing to do right now, and one short follow-up question.
- If they answer your question: use it, go deeper, don't restart.

For any medical or health topic, end your reply with exactly one tag on its own line:
[URGENCY: MONITOR_HOME]
[URGENCY: SEE_VET_SOON]
[URGENCY: SEEK_VET_NOW]

For greetings, general info questions, or small talk — no tag.

Urgency guide — SEEK_VET_NOW: emergency (collapse, seizure, blood, can't breathe). SEE_VET_SOON: needs a vet within 24h (vomiting, limping, not eating, lethargy). MONITOR_HOME: mild, watch and wait.
"""
    }

    static func respond(
        to prompt: String,
        petName: String = "your pet",
        petContext: String = "",
        history: [(role: String, content: String)] = []
    ) async -> TriageResponse {
        guard GroqConfig.isConfigured else {
            return TriageResponse(
                userPrompt: prompt,
                freeText: "PawMD isn't connected yet — your Groq API key isn't set.\n\nTo fix this:\n1. Go to console.groq.com → API Keys → Create a free key\n2. Open Services/GroqConfig.swift in Xcode\n3. Paste your key into the hardcodedKey field\n\nOnce that's done, I'll be able to give real veterinary guidance.",
                urgency: nil
            )
        }

        let context = petContext.isEmpty ? petName : petContext
        var apiMessages: [ChatCompletionRequest.Message] = [
            .init(role: "system", content: buildSystemPrompt(petContext: context))
        ]

        for (role, content) in history {
            apiMessages.append(.init(role: role, content: content))
        }

        apiMessages.append(.init(role: "user", content: prompt))

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
                print("⚠️ Groq HTTP \(httpResponse.statusCode): \(body)")
                if httpResponse.statusCode == 401 {
                    return TriageResponse(
                        userPrompt: prompt,
                        freeText: "The Groq API key was rejected (401 Unauthorized). Please double-check the key in Services/GroqConfig.swift — make sure it starts with gsk_ and was copied in full.",
                        urgency: nil
                    )
                }
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

    private static func parseUrgency(from text: String) -> TriageResponse.Urgency? {
        let upper = text.uppercased()
        if upper.contains("SEEK_VET_NOW") { return .vetNow }
        if upper.contains("SEE_VET_SOON") || upper.contains("VET_WITHIN") { return .vetWithin24h }
        if upper.contains("MONITOR_HOME") || upper.contains("URGENCY:") { return .watchAtHome }
        return nil  // greeting or non-medical — no badge
    }

    /// Offline keyword-based fallback — conversational tone.
    private static func fallbackResponse(for prompt: String, petName: String) -> TriageResponse {
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let lower = trimmed

        // Greetings — don't treat as medical
        let greetings = ["hi", "hello", "hey", "hii", "hiii", "hiiii", "hi there", "hello there",
                         "hey there", "good morning", "good afternoon", "good evening", "howdy"]
        if greetings.contains(where: { trimmed == $0 || trimmed.hasPrefix($0 + " ") || trimmed.hasPrefix($0 + ",") }) {
            return TriageResponse(
                userPrompt: prompt,
                freeText: "Hey! I'm Chintu Ji — ask me anything about your pets or any animal health question. What's on your mind?",
                urgency: nil
            )
        }

        // Short acknowledgements
        let acks = ["ok", "okay", "thanks", "thank you", "got it", "alright", "sure", "yes", "no",
                    "yep", "nope", "understood", "k", "👍", "great"]
        if acks.contains(where: { trimmed == $0 }) {
            return TriageResponse(
                userPrompt: prompt,
                freeText: "Of course — feel free to ask anything else, about any of your pets or just general pet care. I'm here.",
                urgency: nil
            )
        }

        if lower.contains("blood") || lower.contains("seizure") || lower.contains("collapse")
            || lower.contains("unconscious") || lower.contains("not breathing") {
            return TriageResponse(
                userPrompt: prompt,
                freeText: """
What you're describing sounds like a medical emergency — I don't want you to wait on this one. Keep \(petName) as calm and still as possible, somewhere warm, and head straight to your nearest emergency vet clinic now. Don't give any food, water, or medication until a vet has seen them.

Is \(petName) conscious and responding to you right now?

[URGENCY: SEEK_VET_NOW]
""",
                urgency: .vetNow
            )
        }

        if lower.contains("vomit") || lower.contains("diarrhea") || lower.contains("loose stool") {
            return TriageResponse(
                userPrompt: prompt,
                freeText: """
This sounds like a gastrointestinal upset — most likely something \(petName) ate that didn't agree with them, a sudden diet change, or a mild stomach irritation. These usually settle within a day with a bit of rest and dietary management.

For now, hold off food for about 6 to 8 hours but keep fresh water available the whole time. After that, offer small amounts of plain boiled chicken with white rice. If there's any blood in the vomit or stool, or if this goes on past 24 hours, that changes things and I'd want you to see a vet.

How many times has it happened, and does \(petName) seem otherwise alert and interested in their surroundings?

[URGENCY: SEE_VET_SOON]
""",
                urgency: .vetWithin24h
            )
        }

        if lower.contains("itch") || lower.contains("scratch") || lower.contains("skin") || lower.contains("rash") {
            return TriageResponse(
                userPrompt: prompt,
                freeText: """
Scratching like this is most commonly caused by fleas, a food or environmental allergy, or dry skin. The first thing I'd do is check behind the ears, under the armpits, and around the belly for any fleas or ticks, or any red, inflamed patches of skin.

Hold off on bathing for a few days, and keep \(petName)'s bedding washed in hot water. If you've recently changed their food or introduced a new treat, that's worth considering as a trigger too.

Is the scratching focused on one particular spot, or is it all over the body?

[URGENCY: MONITOR_HOME]
""",
                urgency: .watchAtHome
            )
        }

        if lower.contains("letharg") || lower.contains("tired") || lower.contains("not eating") {
            return TriageResponse(
                userPrompt: prompt,
                freeText: """
Lethargy and reduced appetite can mean a lot of things — a mild viral illness, stress from a change in routine, heat fatigue, or occasionally a reaction to something they've eaten. The key thing I'd want to check right now is \(petName)'s gums — they should be pink and moist. Pale or tacky gums are a sign we need to move faster.

Offer water first, then a small amount of their favourite food to see if there's any interest. Let them rest somewhere cool and quiet for now.

How long has this been going on, and has anything changed recently — new food, new environment, or any medications?

[URGENCY: SEE_VET_SOON]
""",
                urgency: .vetWithin24h
            )
        }

        if lower.contains("limping") || lower.contains("leg") || lower.contains("paw") || lower.contains("can't walk") {
            return TriageResponse(
                userPrompt: prompt,
                freeText: """
A limp like this is most often a soft tissue injury — a sprain or strain — especially if there was any recent jumping, running on hard ground, or rough play. A hairline fracture is less common but possible if there was a fall involved.

The most important thing right now is to restrict \(petName)'s movement — keep them in a small, calm space and avoid stairs or jumping. Don't massage the area or apply heat. If the leg is visibly swollen, held off the ground completely, or \(petName) cries when you touch it, that's when I'd want you at the vet today.

Did this come on suddenly after activity, or did you notice it gradually over time?

[URGENCY: SEE_VET_SOON]
""",
                urgency: .vetWithin24h
            )
        }

        return TriageResponse(
            userPrompt: prompt,
            freeText: """
I'd want to know a little more before saying anything definitive. Keep a close eye on them and note any changes in appetite, energy, toilet habits, or general behaviour. If the symptom is visible, a short video is always helpful to show your vet.

If anything worsens, or if they stop eating or drinking entirely, don't wait — get them seen.

Can you tell me a bit more about when this started, which pet you're asking about, and what they were doing just before you noticed it?

[URGENCY: MONITOR_HOME]
""",
            urgency: .watchAtHome
        )
    }
}