import Foundation

/// Expands a `Reminder`'s `Recurrence` into concrete `ReminderInstance`
/// occurrences within a date window. Pure / testable — no SwiftData imports.
enum RecurrenceEngine {
    /// Returns occurrence `Date`s between `start` (inclusive) and `end` (exclusive)
    /// based on `firstDueAt` and `recurrence`.
    static func occurrences(
        recurrence: Recurrence,
        firstDueAt: Date,
        in range: Range<Date>,
        calendar: Calendar = .current
    ) -> [Date] {
        var cal = calendar
        cal.timeZone = calendar.timeZone
        var dates: [Date] = []
        let hardCap = 1000  // safety

        switch recurrence {
        case .once:
            if range.contains(firstDueAt) { dates.append(firstDueAt) }

        case .daily:
            var cursor = firstDueAt
            while cursor < range.upperBound, dates.count < hardCap {
                if cursor >= range.lowerBound { dates.append(cursor) }
                guard let next = cal.date(byAdding: .day, value: 1, to: cursor) else { break }
                cursor = next
            }

        case .everyNDays(let n):
            let step = max(1, n)
            var cursor = firstDueAt
            while cursor < range.upperBound, dates.count < hardCap {
                if cursor >= range.lowerBound { dates.append(cursor) }
                guard let next = cal.date(byAdding: .day, value: step, to: cursor) else { break }
                cursor = next
            }

        case .weekly(let weekdays):
            // Walk day-by-day starting from firstDueAt; emit when weekday matches.
            var cursor = firstDueAt
            while cursor < range.upperBound, dates.count < hardCap {
                let wd = cal.component(.weekday, from: cursor)
                if weekdays.contains(wd), cursor >= range.lowerBound {
                    dates.append(cursor)
                }
                guard let next = cal.date(byAdding: .day, value: 1, to: cursor) else { break }
                cursor = next
            }

        case .monthly(let day):
            dates.append(contentsOf: monthlyOccurrences(
                startingFrom: firstDueAt,
                monthStep: 1,
                dayOfMonth: day,
                in: range,
                calendar: cal,
                cap: hardCap
            ))

        case .everyNMonths(let n, let day):
            dates.append(contentsOf: monthlyOccurrences(
                startingFrom: firstDueAt,
                monthStep: max(1, n),
                dayOfMonth: day,
                in: range,
                calendar: cal,
                cap: hardCap
            ))
        }

        return dates
    }

    // MARK: - Helpers

    private static func monthlyOccurrences(
        startingFrom firstDueAt: Date,
        monthStep: Int,
        dayOfMonth: Int,
        in range: Range<Date>,
        calendar cal: Calendar,
        cap: Int
    ) -> [Date] {
        var out: [Date] = []

        // Anchor: snap firstDueAt to dayOfMonth in its month, preserving time-of-day.
        var comps = cal.dateComponents([.year, .month, .hour, .minute, .second], from: firstDueAt)
        comps.day = dayOfMonth
        guard var cursor = cal.date(from: comps) else { return out }

        // If cursor < firstDueAt (original was later in month), advance by step.
        if cursor < firstDueAt {
            guard let advanced = cal.date(byAdding: .month, value: monthStep, to: cursor) else { return out }
            cursor = advanced
        }

        while cursor < range.upperBound, out.count < cap {
            if cursor >= range.lowerBound { out.append(cursor) }
            guard let next = cal.date(byAdding: .month, value: monthStep, to: cursor) else { break }
            cursor = next
        }
        return out
    }
}
