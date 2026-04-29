import Foundation
import SwiftData

enum Mood: String, Codable, CaseIterable, Identifiable {
    case happy, playful, calm, tired, anxious, sick
    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .happy:   return "😺"
        case .playful: return "🥎"
        case .calm:    return "☁️"
        case .tired:   return "💤"
        case .anxious: return "😟"
        case .sick:    return "🤒"
        }
    }

    var label: String {
        switch self {
        case .happy:   return "Happy"
        case .playful: return "Playful"
        case .calm:    return "Calm"
        case .tired:   return "Tired"
        case .anxious: return "Anxious"
        case .sick:    return "Sick"
        }
    }
}

@Model
final class MoodEntry {
    @Attribute(.unique) var id: UUID = UUID()
    var pet: Pet?
    var moodRaw: String
    var at: Date

    init(id: UUID = UUID(), pet: Pet? = nil, mood: Mood, at: Date = .now) {
        self.id = id
        self.pet = pet
        self.moodRaw = mood.rawValue
        self.at = at
    }

    var mood: Mood { Mood(rawValue: moodRaw) ?? .happy }
}
