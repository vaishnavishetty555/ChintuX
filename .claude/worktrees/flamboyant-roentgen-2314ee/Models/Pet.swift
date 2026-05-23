import Foundation
import SwiftData

/// PRD §6.7 — Per-pet profile with hero photo, breed, DOB, medical info.
@Model
final class Pet {
    // Identity
    @Attribute(.unique) var id: UUID = UUID()
    var name: String
    var speciesRaw: String           // Species.rawValue
    var breed: String
    var dateOfBirth: Date?

    // Stats
    var weightKg: Double?
    var sexRaw: String               // PetSex.rawValue
    var neutered: Bool

    // Medical
    var allergiesText: String        // comma-separated free text
    var ongoingConditionsText: String

    // Household accent (per-pet color)
    var accentHex: String

    // Photo stored inline as JPEG data for V1 simplicity
    @Attribute(.externalStorage) var photoData: Data?

    // Lifecycle status
    var statusRaw: String            // PetStatus.rawValue
    var markedPassedAt: Date?
    var markedLostAt: Date?

    // Vet contact (free text for V1)
    var vetName: String
    var vetPhone: String

    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \Reminder.pet)
    var reminders: [Reminder] = []

    @Relationship(deleteRule: .cascade, inverse: \LogEntry.pet)
    var logEntries: [LogEntry] = []

    @Relationship(deleteRule: .cascade, inverse: \MoodEntry.pet)
    var moodEntries: [MoodEntry] = []

    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        species: Species,
        breed: String = "",
        dateOfBirth: Date? = nil,
        weightKg: Double? = nil,
        sex: PetSex = .unknown,
        neutered: Bool = false,
        allergiesText: String = "",
        ongoingConditionsText: String = "",
        accentHex: String = PawlyColorsStatic.defaultAccent,
        photoData: Data? = nil,
        status: PetStatus = .active,
        vetName: String = "",
        vetPhone: String = "",
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.speciesRaw = species.rawValue
        self.breed = breed
        self.dateOfBirth = dateOfBirth
        self.weightKg = weightKg
        self.sexRaw = sex.rawValue
        self.neutered = neutered
        self.allergiesText = allergiesText
        self.ongoingConditionsText = ongoingConditionsText
        self.accentHex = accentHex
        self.photoData = photoData
        self.statusRaw = status.rawValue
        self.vetName = vetName
        self.vetPhone = vetPhone
        self.createdAt = createdAt
    }

    // Computed accessors
    var species: Species { Species(rawValue: speciesRaw) ?? .dog }
    var sex: PetSex { PetSex(rawValue: sexRaw) ?? .unknown }
    var status: PetStatus {
        get { PetStatus(rawValue: statusRaw) ?? .active }
        set { statusRaw = newValue.rawValue }
    }

    /// Years + months string e.g. "3y 2mo", "9mo"
    var ageDescription: String {
        guard let dob = dateOfBirth else { return "Unknown age" }
        let comps = Calendar.current.dateComponents([.year, .month], from: dob, to: .now)
        let y = comps.year ?? 0
        let m = comps.month ?? 0
        if y == 0 { return "\(max(0, m))mo" }
        if m == 0 { return "\(y)y" }
        return "\(y)y \(m)mo"
    }
}

/// Static constants used by SwiftData `@Model` default-value arguments (which
/// require values available at model-init time without importing SwiftUI).
enum PawlyColorsStatic {
    static let defaultAccent = "#2D5F4E"
}
