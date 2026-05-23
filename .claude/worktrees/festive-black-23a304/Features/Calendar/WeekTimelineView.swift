import SwiftUI

/// PRD §6.4 — Simple 7-day vertical timeline for users on multi-med courses.
struct WeekTimelineView: View {
    let anchor: Date
    let pets: [Pet]

    private let cal = Calendar.current

    private var weekDays: [Date] {
        let start = cal.dateInterval(of: .weekOfYear, for: anchor)?.start ?? anchor
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: start) }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.s) {
                ForEach(weekDays, id: \.self) { day in
                    DayColumn(day: day, pets: pets)
                }
            }
            .padding(.vertical, Spacing.m)
        }
    }
}

private struct DayColumn: View {
    let day: Date
    let pets: [Pet]

    private var instances: [ReminderInstance] {
        let start = day.startOfDay
        let end = day.endOfDay
        return pets.flatMap(\.reminders)
            .flatMap(\.instances)
            .filter { $0.scheduledAt >= start && $0.scheduledAt <= end }
            .sorted { $0.scheduledAt < $1.scheduledAt }
    }

    var body: some View {
        PawlyCard {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(day, format: .dateTime.weekday(.wide).month(.abbreviated).day())
                    .font(PawlyFont.headingMedium)
                    .foregroundStyle(PawlyColors.ink)
                if instances.isEmpty {
                    Text("—").font(PawlyFont.bodyMedium).foregroundStyle(PawlyColors.slate)
                } else {
                    ForEach(instances) { inst in
                        HStack(spacing: Spacing.s) {
                            Text(inst.scheduledAt, format: .dateTime.hour().minute())
                                .font(PawlyFont.tabularSmall)
                                .foregroundStyle(PawlyColors.slate)
                                .frame(width: 56, alignment: .leading)
                            if let sym = inst.reminder?.type.sfSymbol {
                                Image(systemName: sym).foregroundStyle(PawlyColors.forest)
                            }
                            Text(inst.reminder?.title ?? "Reminder")
                                .font(PawlyFont.bodyMedium)
                                .foregroundStyle(PawlyColors.ink)
                            Spacer()
                            StatusDot(status: statusFor(inst), size: 8)
                        }
                    }
                }
            }
        }
    }

    private func statusFor(_ inst: ReminderInstance) -> StatusDot.Status {
        switch inst.status {
        case .completed: return .completed
        case .upcoming, .snoozed:
            return inst.scheduledAt < .now ? .missed : .upcoming
        case .missed: return .missed
        case .skipped: return .upcoming
        }
    }
}
