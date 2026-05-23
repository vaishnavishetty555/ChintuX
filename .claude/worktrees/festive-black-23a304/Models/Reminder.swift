import Foundation
import SwiftData

@Model
final class Reminder {
    @Attribute(.unique) var id: UUID = UUID()
    var pet: Pet?

    var title: String
    var typeRaw: String               // ReminderType.rawValue
    var dosage: String?
    var recurrenceRaw: String         // Recurrence.rawString
    var firstDueAt: Date
    var notes: String
    @Attribute(.externalStorage) var prescriptionPhotoData: Data?

    // Quiet hours window (per-reminder override; 0 if unused).
    var quietStartHour: Int           // 0..23 or -1 to disable
    var quietEndHour: Int             // 0..23

    var createdAt: Date
    var isActive: Bool

    @Relationship(deleteRule: .cascade, inverse: \ReminderInstance.reminder)
    var instances: [ReminderInstance] = []

    init(
        id: UUID = UUID(),
        pet: Pet? = nil,
        title: String,
        type: ReminderType,
        dosage: String? = nil,
        recurrence: Recurrence,
        firstDueAt: Date,
        notes: String = "",
        prescriptionPhotoData: Data? = nil,
        quietStartHour: Int = -1,
        quietEndHour: Int = -1,
        isActive: Bool = true,
        createdAt: Date = .now
    ) {
        self.id = id
        self.pet = pet
        self.title = title
        self.typeRaw = type.rawValue
        self.dosage = dosage
        self.recurrenceRaw = recurrence.rawString
        self.firstDueAt = firstDueAt
        self.notes = notes
        self.prescriptionPhotoData = prescriptionPhotoData
        self.quietStartHour = quietStartHour
        self.quietEndHour = quietEndHour
        self.isActive = isActive
        self.createdAt = createdAt
    }

    var type: ReminderType { ReminderType(rawValue: typeRaw) ?? .custom }
    var recurrence: Recurrence {
        Recurrence(rawString: recurrenceRaw) ?? .once
    }
}
