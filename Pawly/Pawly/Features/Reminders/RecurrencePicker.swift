import SwiftUI

/// PRD §6.3 — Recurrence picker. Inline custom UI to avoid native system sheets.
struct RecurrencePicker: View {
    @Binding var recurrence: Recurrence

    // Local editable state for compound cases.
    @State private var everyNDaysCount: Int = 1
    @State private var everyNMonthsCount: Int = 1
    @State private var monthlyDay: Int = 1
    @State private var weekdays: Set<Int> = []

    enum Kind: String, CaseIterable, Identifiable {
        case once, daily, everyNDays, weekly, monthly, everyNMonths
        var id: String { rawValue }
        var label: String {
            switch self {
            case .once: return "Once"
            case .daily: return "Daily"
            case .everyNDays: return "Every N days"
            case .weekly: return "Weekly"
            case .monthly: return "Monthly"
            case .everyNMonths: return "Every N months"
            }
        }
    }

    @State private var kind: Kind = .once

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text("Repeat").font(PawlyFont.caption).foregroundStyle(PawlyColors.slate)

            Picker("Kind", selection: $kind) {
                ForEach(Kind.allCases) { k in Text(k.label).tag(k) }
            }
            .pickerStyle(.menu)
            .tint(PawlyColors.forest)
            .frame(minHeight: Spacing.tapTargetMin, alignment: .leading)

            switch kind {
            case .once, .daily:
                EmptyView()
            case .everyNDays:
                Stepper("Every \(everyNDaysCount) day\(everyNDaysCount == 1 ? "" : "s")",
                        value: $everyNDaysCount, in: 1...60)
            case .weekly:
                WeekdaySelector(selection: $weekdays)
            case .monthly:
                Stepper("Day \(monthlyDay) of each month",
                        value: $monthlyDay, in: 1...28)
            case .everyNMonths:
                Stepper("Every \(everyNMonthsCount) month\(everyNMonthsCount == 1 ? "" : "s")",
                        value: $everyNMonthsCount, in: 1...24)
                Stepper("On day \(monthlyDay)", value: $monthlyDay, in: 1...28)
            }
        }
        .onAppear(perform: loadFromRecurrence)
        .onChange(of: kind)              { _, _ in commit() }
        .onChange(of: everyNDaysCount)   { _, _ in commit() }
        .onChange(of: everyNMonthsCount) { _, _ in commit() }
        .onChange(of: monthlyDay)        { _, _ in commit() }
        .onChange(of: weekdays)          { _, _ in commit() }
    }

    private func loadFromRecurrence() {
        switch recurrence {
        case .once:           kind = .once
        case .daily:          kind = .daily
        case .everyNDays(let n):
            kind = .everyNDays; everyNDaysCount = n
        case .weekly(let days):
            kind = .weekly; weekdays = days
        case .monthly(let d):
            kind = .monthly; monthlyDay = d
        case .everyNMonths(let n, let d):
            kind = .everyNMonths; everyNMonthsCount = n; monthlyDay = d
        }
    }

    private func commit() {
        switch kind {
        case .once:          recurrence = .once
        case .daily:         recurrence = .daily
        case .everyNDays:    recurrence = .everyNDays(max(1, everyNDaysCount))
        case .weekly:
            recurrence = .weekly(weekdays: weekdays.isEmpty ? [Calendar.current.component(.weekday, from: .now)] : weekdays)
        case .monthly:       recurrence = .monthly(day: monthlyDay)
        case .everyNMonths:  recurrence = .everyNMonths(max(1, everyNMonthsCount), day: monthlyDay)
        }
    }
}

struct WeekdaySelector: View {
    @Binding var selection: Set<Int>
    private let labels = ["S","M","T","W","T","F","S"]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(1...7, id: \.self) { wd in
                Button {
                    if selection.contains(wd) { selection.remove(wd) }
                    else { selection.insert(wd) }
                } label: {
                    Text(labels[wd - 1])
                        .font(PawlyFont.caption)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(selection.contains(wd) ? PawlyColors.forest : PawlyColors.surface)
                        )
                        .foregroundStyle(selection.contains(wd) ? Color.white : PawlyColors.ink)
                        .overlay(Circle().stroke(PawlyColors.sand, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
    }
}
