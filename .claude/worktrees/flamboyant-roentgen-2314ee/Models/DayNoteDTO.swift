import Foundation

/// A simple day note tied to a pet and a calendar date (stored as start-of-day).
struct DayNoteDTO: Codable, Identifiable, Hashable {
    let id: UUID
    let petId: UUID?
    let day: Date
    let body: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case petId = "pet_id"
        case day
        case body
        case createdAt = "created_at"
    }

    init(
        id: UUID = UUID(),
        petId: UUID? = nil,
        day: Date,
        body: String,
        createdAt: Date = .now
    ) {
        self.id = id
        self.petId = petId
        self.day = day
        self.body = body
        self.createdAt = createdAt
    }
}
