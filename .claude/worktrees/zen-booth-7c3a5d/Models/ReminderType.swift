import Foundation

/// PRD §6.3 — Reminder types.
enum ReminderType: String, Codable, CaseIterable, Identifiable {
    case medication
    case vaccination
    case dewormingTickFlea
    case vetCheckup
    case grooming
    case weightCheck
    case custom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .medication:        return "Medication"
        case .vaccination:       return "Vaccination"
        case .dewormingTickFlea: return "Deworming / Tick & Flea"
        case .vetCheckup:        return "Vet Checkup"
        case .grooming:          return "Grooming / Bath"
        case .weightCheck:       return "Weight Check"
        case .custom:            return "Custom"
        }
    }

    var sfSymbol: String {
        switch self {
        case .medication:        return "pills.fill"
        case .vaccination:       return "syringe.fill"
        case .dewormingTickFlea: return "drop.fill"
        case .vetCheckup:        return "stethoscope"
        case .grooming:          return "scissors"
        case .weightCheck:       return "scalemass.fill"
        case .custom:            return "bell.fill"
        }
    }

    var titlePlaceholder: String {
        switch self {
        case .medication:        return "Deworming tablet"
        case .vaccination:       return "Rabies vaccine"
        case .dewormingTickFlea: return "Tick & flea treatment"
        case .vetCheckup:        return "Annual checkup"
        case .grooming:          return "Bath & brush"
        case .weightCheck:       return "Monthly weigh-in"
        case .custom:            return "Reminder title"
        }
    }
}
