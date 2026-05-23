import Foundation
import SwiftData

enum LogKind: String, Codable, CaseIterable, Identifiable {
    case meal
    case medication
    case walk
    case weight
    case hygiene

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .meal:       return "Meal"
        case .medication: return "Medication"
        case .walk:       return "Walk"
        case .weight:     return "Weight"
        case .hygiene:    return "Hygiene"
        }
    }
    var sfSymbol: String {
        switch self {
        case .meal:       return "fork.knife"
        case .medication: return "pills.fill"
        case .walk:       return "figure.walk"
        case .weight:     return "scalemass.fill"
        case .hygiene:    return "drop.fill"
        }
    }
}

@Model
final class LogEntry {
    @Attribute(.unique) var id: UUID = UUID()
    var pet: Pet?

    var kindRaw: String
    var detail: String
    var numericValue: Double?   // for weight entries etc.
    var at: Date

    init(
        id: UUID = UUID(),
        pet: Pet? = nil,
        kind: LogKind,
        detail: String = "",
        numericValue: Double? = nil,
        at: Date = .now
    ) {
        self.id = id
        self.pet = pet
        self.kindRaw = kind.rawValue
        self.detail = detail
        self.numericValue = numericValue
        self.at = at
    }

    var kind: LogKind { LogKind(rawValue: kindRaw) ?? .meal }
}
