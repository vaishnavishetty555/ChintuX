import SwiftUI

/// PRD §6.4 — Month grid. Each cell shows up to three colored dots for that day.
struct MonthGrid: View {
    let anchor: Date
    let pets: [Pet]
    var onTapDay: (Date) -> Void

    private let cal = Calendar.current
    private let weekdayHeaders = ["S", "M", "T", "W", "T", "F", "S"]

    var body: some View {
        VStack(spacing: Spacing.xs) {
            // Weekday header row
            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { i in
                    Text(weekdayHeaders[i])
                        .font(PawlyFont.caption)
                        .foregroundStyle(PawlyColors.slate)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 2)

            let cells = computeCells()
            let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(Array(cells.enumerated()), id: \.offset) { _, cell in
                    if let day = cell {
                        DayCell(
                            day: day,
                            statuses: statuses(for: day),
                            isToday: cal.isDateInToday(day)
                        )
                        .onTapGesture { onTapDay(day) }
                    } else {
                        Color.clear.frame(height: 56)
                    }
                }
            }
        }
    }

    /// Produces a 7-column array padded with nils so the first day of month
    /// lands under its correct weekday column.
    private func computeCells() -> [Date?] {
        let comps = cal.dateComponents([.year, .month], from: anchor)
        guard let monthStart = cal.date(from: comps) else { return [] }
        let offset = cal.firstWeekdayOffset(for: monthStart)
        let days = Date.daysInMonth(containing: monthStart)
        var cells: [Date?] = Array(repeating: nil, count: offset)
        cells.append(contentsOf: days.map { Optional($0) })
        while cells.count % 7 != 0 { cells.append(nil) }
        return cells
    }

    private func statuses(for day: Date) -> [ReminderInstanceStatus] {
        let dayStart = day.startOfDay
        let dayEnd = day.endOfDay
        return pets.flatMap(\.reminders)
            .flatMap(\.instances)
            .filter { $0.scheduledAt >= dayStart && $0.scheduledAt <= dayEnd }
            .map { inst -> ReminderInstanceStatus in
                if inst.status == .completed { return .completed }
                if inst.status == .upcoming, inst.scheduledAt < .now { return .missed }
                return inst.status
            }
    }
}

private struct DayCell: View {
    let day: Date
    let statuses: [ReminderInstanceStatus]
    let isToday: Bool

    var body: some View {
        VStack(spacing: 4) {
            Text("\(Calendar.current.component(.day, from: day))")
                .font(PawlyFont.tabularSmall)
                .foregroundStyle(isToday ? Color.white : PawlyColors.ink)
                .frame(width: 26, height: 26)
                .background(
                    Circle().fill(isToday ? PawlyColors.forest : Color.clear)
                )
            HStack(spacing: 2) {
                ForEach(0..<min(3, statuses.count), id: \.self) { i in
                    dotView(for: statuses[i])
                }
                if statuses.count > 3 {
                    Text("+").font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(PawlyColors.slate)
                }
                if statuses.isEmpty {
                    Color.clear.frame(height: 6)
                }
            }
            .frame(height: 8)
        }
        .frame(maxWidth: .infinity, minHeight: 56)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func dotView(for status: ReminderInstanceStatus) -> some View {
        switch status {
        case .completed:
            StatusDot(status: .completed, size: 7)
        case .upcoming, .snoozed:
            StatusDot(status: .upcoming, size: 7)
        case .missed:
            StatusDot(status: .missed, size: 7)
        case .skipped:
            StatusDot(status: .upcoming, size: 7).opacity(0.5)
        }
    }
}
