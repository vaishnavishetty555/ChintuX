import Foundation
import SwiftData

/// Deterministic seed data used for previews and for first-run demo toggling.
enum SeedData {
    /// Inserts 2 pets (Mochi + Pebble) and a handful of reminders + logs into
    /// the given context. Safe to call on an empty store only.
    @MainActor
    static func seed(into context: ModelContext) {
        let calendar = Calendar.current
        let now = Date()

        // Pets
        let mochi = Pet(
            name: "Mochi",
            species: .cat,
            breed: "Persian",
            dateOfBirth: calendar.date(byAdding: .year, value: -3, to: now),
            weightKg: 4.2,
            sex: .female,
            neutered: true,
            allergiesText: "Fish",
            ongoingConditionsText: "",
            accentHex: "#2D5F4E"
        )
        let pebble = Pet(
            name: "Pebble",
            species: .cat,
            breed: "Indian Billi",
            dateOfBirth: calendar.date(byAdding: .month, value: -13, to: now),
            weightKg: 3.1,
            sex: .male,
            neutered: false,
            accentHex: "#E8A87C"
        )
        context.insert(mochi)
        context.insert(pebble)

        // Reminders for Mochi
        let deworming = Reminder(
            pet: mochi,
            title: "Monthly deworming",
            type: .dewormingTickFlea,
            dosage: "1 tablet",
            recurrence: .monthly(day: calendar.component(.day, from: now)),
            firstDueAt: now,
            notes: "After breakfast."
        )
        let vitamin = Reminder(
            pet: mochi,
            title: "Vitamin drops",
            type: .medication,
            dosage: "2 drops",
            recurrence: .daily,
            firstDueAt: calendar.date(bySettingHour: 9, minute: 0, second: 0, of: now) ?? now
        )
        let vaccine = Reminder(
            pet: pebble,
            title: "Annual vaccination",
            type: .vaccination,
            recurrence: .everyNMonths(12, day: calendar.component(.day, from: now)),
            firstDueAt: calendar.date(byAdding: .month, value: 2, to: now) ?? now,
            notes: "Book with Dr. Mehta."
        )
        [deworming, vitamin, vaccine].forEach { context.insert($0) }

        // Expand reminders to instances for the next 90 days
        let windowEnd = calendar.date(byAdding: .day, value: 90, to: now) ?? now
        let windowStart = calendar.date(byAdding: .day, value: -14, to: now) ?? now
        for reminder in [deworming, vitamin, vaccine] {
            let dates = RecurrenceEngine.occurrences(
                recurrence: reminder.recurrence,
                firstDueAt: reminder.firstDueAt,
                in: windowStart..<windowEnd
            )
            for d in dates {
                let inst = ReminderInstance(reminder: reminder, scheduledAt: d)
                // Mark some past instances as completed for adherence streaks
                if d < now, Bool.random() || d < calendar.date(byAdding: .day, value: -3, to: now)! {
                    inst.status = .completed
                    inst.completedAt = d
                } else if d < now {
                    inst.status = .missed
                }
                context.insert(inst)
            }
        }

        // A handful of log entries for the activity feed
        context.insert(LogEntry(pet: mochi, kind: .meal, detail: "Half pouch wet food", at: calendar.date(byAdding: .hour, value: -2, to: now) ?? now))
        context.insert(LogEntry(pet: mochi, kind: .medication, detail: "Vitamin drops x2", at: calendar.date(byAdding: .hour, value: -4, to: now) ?? now))
        context.insert(LogEntry(pet: pebble, kind: .walk, detail: "15 minute balcony play", at: calendar.date(byAdding: .hour, value: -6, to: now) ?? now))
        context.insert(MoodEntry(pet: mochi, mood: .happy, at: now))
        context.insert(MoodEntry(pet: pebble, mood: .playful, at: now))
    }
}
