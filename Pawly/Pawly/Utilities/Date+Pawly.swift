import Foundation

extension Date {
    /// Start of day (midnight local).
    var startOfDay: Date { Calendar.current.startOfDay(for: self) }

    /// End of day (last instant before next midnight).
    var endOfDay: Date {
        let cal = Calendar.current
        return cal.date(byAdding: DateComponents(day: 1, second: -1), to: startOfDay) ?? self
    }

    /// Days between (self = later) and `other`. Positive if self is after other.
    func daysFrom(_ other: Date) -> Int {
        Calendar.current.dateComponents([.day], from: other.startOfDay, to: self.startOfDay).day ?? 0
    }

    func isSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
    }

    static func daysInMonth(containing date: Date) -> [Date] {
        let cal = Calendar.current
        guard let range = cal.range(of: .day, in: .month, for: date),
              let first = cal.date(from: cal.dateComponents([.year, .month], from: date))
        else { return [] }
        return range.compactMap { d -> Date? in
            cal.date(byAdding: .day, value: d - 1, to: first)
        }
    }
}

extension Calendar {
    /// Index (0 = Sunday) used by the month grid to place the first day of
    /// the month in the correct column.
    func firstWeekdayOffset(for monthStart: Date) -> Int {
        let weekday = component(.weekday, from: monthStart) // 1..7, Sun=1
        return (weekday - firstWeekday + 7) % 7
    }
}
