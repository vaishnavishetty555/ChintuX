import Foundation

/// PRD §6.5 — AI Doctor responses. Structured into 4 parts with urgency +
/// confidence. No network — picks a canned response by keyword heuristics.
struct TriageResponse: Hashable, Identifiable {
    enum Urgency: String {
        case watchAtHome = "Watch at home"
        case vetWithin24h = "Vet within 24 hours"
        case vetNow = "Vet now"

        var colorHint: String { // used for tinting, mapped in view layer
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
}

enum MockAIDoctorService {
    /// Returns a structured triage response for the given free-text symptom prompt.
    static func respond(to prompt: String, petName: String = "your pet") -> TriageResponse {
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
                confidence: .high,
                createdAt: .now
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
                confidence: .medium,
                createdAt: .now
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
                confidence: .medium,
                createdAt: .now
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
                confidence: .medium,
                createdAt: .now
            )
        }

        // Default fallback — generic but honestly low-confidence.
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
            confidence: .low,
            createdAt: .now
        )
    }
}
