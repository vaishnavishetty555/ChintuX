import SwiftUI
import SwiftData

/// PRD §6.4 — Bottom sheet expansion of a calendar day.
struct DayDetailSheet: View {
    let day: Date
    let pets: [Pet]

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    private var timeline: [ReminderInstance] {
        let start = day.startOfDay
        let end = day.endOfDay
        return pets.flatMap(\.reminders)
            .flatMap(\.instances)
            .filter { $0.scheduledAt >= start && $0.scheduledAt <= end }
            .sorted { $0.scheduledAt < $1.scheduledAt }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s) {
                    if timeline.isEmpty {
                        PawlyCard {
                            Text("No reminders scheduled for this day. Enjoy the quiet.")
                                .font(PawlyFont.bodyMedium)
                                .foregroundStyle(PawlyColors.slate)
                        }
                    } else {
                        ForEach(timeline) { inst in
                            TimelineRow(instance: inst,
                                        onToggle: { toggle(inst) })
                        }
                    }
                }
                .padding(.horizontal, Spacing.screenHorizontal)
                .padding(.top, Spacing.m)
                .padding(.bottom, Spacing.xxl)
            }
            .background(PawlyColors.cream.ignoresSafeArea())
            .navigationTitle(day.formatted(.dateTime.weekday(.wide).day().month(.wide)))
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func toggle(_ inst: ReminderInstance) {
        Haptics.success()
        switch inst.status {
        case .completed:
            inst.status = .upcoming
            inst.completedAt = nil
        default:
            inst.status = .completed
            inst.completedAt = .now
        }
        try? modelContext.save()
    }
}

private struct TimelineRow: View {
    let instance: ReminderInstance
    var onToggle: () -> Void

    var body: some View {
        PawlyCard {
            HStack(spacing: Spacing.m) {
                Text(instance.scheduledAt, format: .dateTime.hour().minute())
                    .font(PawlyFont.tabularSmall)
                    .foregroundStyle(PawlyColors.slate)
                    .frame(width: 56, alignment: .leading)

                if let type = instance.reminder?.type {
                    Image(systemName: type.sfSymbol)
                        .foregroundStyle(petAccent)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(PawlyColors.cream))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(instance.reminder?.title ?? "Reminder")
                        .font(PawlyFont.bodyLarge).foregroundStyle(PawlyColors.ink)
                    Text(instance.reminder?.pet?.name ?? "")
                        .font(PawlyFont.caption).foregroundStyle(PawlyColors.slate)
                }

                Spacer()

                Button(action: onToggle) {
                    Image(systemName: instance.status == .completed
                          ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 26))
                        .foregroundStyle(instance.status == .completed ? PawlyColors.sage : PawlyColors.slate)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(instance.status == .completed ? "Mark as upcoming" : "Mark done")
            }
        }
    }

    private var petAccent: Color {
        Color(hex: instance.reminder?.pet?.accentHex ?? "#2D5F4E")
    }
}
