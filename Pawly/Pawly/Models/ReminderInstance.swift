import Foundation
import SwiftData

enum ReminderInstanceStatus: String, Codable, CaseIterable {
    case upcoming
    case completed
    case missed
    case snoozed
    case skipped
}

@Model
final class ReminderInstance {
    @Attribute(.unique) var id: UUID = UUID()
    var reminder: Reminder?

    var scheduledAt: Date
    var statusRaw: String = ReminderInstanceStatus.upcoming.rawValue
    var completedAt: Date?
    var snoozedUntil: Date?

    init(
        id: UUID = UUID(),
        reminder: Reminder? = nil,
        scheduledAt: Date,
        status: ReminderInstanceStatus = .upcoming,
        completedAt: Date? = nil,
        snoozedUntil: Date? = nil
    ) {
        self.id = id
        self.reminder = reminder
        self.scheduledAt = scheduledAt
        self.statusRaw = status.rawValue
        self.completedAt = completedAt
        self.snoozedUntil = snoozedUntil
    }

    var status: ReminderInstanceStatus {
        get { ReminderInstanceStatus(rawValue: statusRaw) ?? .upcoming }
        set { statusRaw = newValue.rawValue }
    }
}
