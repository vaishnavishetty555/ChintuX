import SwiftUI

/// Calendar tab — month or week view with status dots, day bottom sheet.
struct CalendarView: View {
    enum Mode { case month, week }

    @EnvironmentObject var petContext: PetContextStore
    @EnvironmentObject var dataStore: DataStore
    @State private var anchor: Date = Date()
    @State private var mode: Mode = .month
    @State private var showingDaySheet: Date?
    @State private var filterPetID: UUID?
    @State private var showingAddReminder = false

    var body: some View {
        VStack(spacing: 0) {
            header
            petFilterRow

            if mode == .month {
                MonthGridDTO(
                    anchor: anchor,
                    dataStore: dataStore,
                    filterPetID: filterPetID,
                    onTapDay: { day in
                        Haptics.light()
                        showingDaySheet = day
                    }
                )
                .padding(.horizontal, Spacing.screenHorizontal)
                .gesture(
                    DragGesture(minimumDistance: 40)
                        .onEnded { value in
                            if value.translation.width < -60 {
                                withAnimation(.easeInOut(duration: 0.3)) { mode = .week }
                            }
                        }
                )
            } else {
                WeekTimelineViewDTO(anchor: anchor, dataStore: dataStore, filterPetID: filterPetID)
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .gesture(
                        DragGesture(minimumDistance: 40)
                            .onEnded { value in
                                if value.translation.width > 60 {
                                    withAnimation(.easeInOut(duration: 0.3)) { mode = .month }
                                }
                            }
                    )
            }

            adherenceRow
        }
        .background(PawlyColors.cream.ignoresSafeArea())
        .navigationTitle("Calendar")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Haptics.light()
                    showingAddReminder = true
                } label: {
                    Image(systemName: "plus")
                }
                .tint(PawlyColors.forest)
                .disabled(dataStore.pets.isEmpty)
            }
        }
        .sheet(item: Binding(
            get: { showingDaySheet.map { DayID(date: $0) } },
            set: { showingDaySheet = $0?.date }
        )) { id in
            DayDetailSheetDTO(day: id.date, dataStore: dataStore, filterPetID: filterPetID)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingAddReminder) {
            AddReminderPickerViewDTO(dataStore: dataStore, filterPetID: $filterPetID)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: Spacing.s) {
            PetSwitcherCarousel(pets: dataStore.pets)
            Spacer()

            Button {
                Haptics.light()
                withAnimation(.easeInOut(duration: 0.3)) { anchor = shift(by: -1) }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(PawlyColors.ink)
            }

            Text(headerTitle)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(PawlyColors.ink)
                .frame(minWidth: 140)

            Button {
                Haptics.light()
                withAnimation(.easeInOut(duration: 0.3)) { anchor = shift(by: 1) }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(PawlyColors.ink)
            }

            Menu {
                Button("Month view") { mode = .month }
                Button("Week view")  { mode = .week }
            } label: {
                Image(systemName: "calendar")
                    .font(.system(size: 16))
                    .foregroundStyle(PawlyColors.forest)
            }
        }
        .padding(.horizontal, Spacing.screenHorizontal)
        .padding(.top, Spacing.m)
        .padding(.bottom, Spacing.s)
    }

    private var headerTitle: String {
        let f = DateFormatter()
        if mode == .month {
            f.dateFormat = "LLLL yyyy"
            return f.string(from: anchor)
        } else {
            let cal = Calendar.current
            let start = cal.dateInterval(of: .weekOfYear, for: anchor)?.start ?? anchor
            let end = cal.date(byAdding: .day, value: 6, to: start) ?? anchor
            let df = DateFormatter(); df.dateFormat = "MMM d"
            return "\(df.string(from: start)) – \(df.string(from: end))"
        }
    }

    private func shift(by n: Int) -> Date {
        let cal = Calendar.current
        switch mode {
        case .month: return cal.date(byAdding: .month, value: n, to: anchor) ?? anchor
        case .week:  return cal.date(byAdding: .weekOfYear, value: n, to: anchor) ?? anchor
        }
    }

    // MARK: - Pet filter chips

    private var petFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                chip("All", color: PawlyColors.forest, active: filterPetID == nil) {
                    filterPetID = nil
                }
                ForEach(dataStore.pets) { pet in
                    chip(pet.name, color: Color(hex: pet.accentHex), active: filterPetID == pet.id) {
                        filterPetID = pet.id
                    }
                }
            }
            .padding(.horizontal, Spacing.screenHorizontal)
        }
        .padding(.bottom, Spacing.s)
    }

    @ViewBuilder
    private func chip(_ label: String, color: Color, active: Bool, onTap: @escaping () -> Void) -> some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Circle().fill(color).frame(width: 7, height: 7)
                Text(label).font(.system(size: 11, weight: .semibold))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(active ? color.opacity(0.15) : PawlyColors.surface)
            )
            .overlay(
                Capsule().stroke(active ? color : PawlyColors.sand.opacity(0.5), lineWidth: 0.75)
            )
            .foregroundStyle(active ? color : PawlyColors.slate)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Adherence row

    private var adherenceRow: some View {
        let cal = Calendar.current
        let start = cal.date(byAdding: .day, value: -30, to: .now) ?? .now

        let petIds = filterPetID != nil ? [filterPetID!] : dataStore.pets.map { $0.id }
        let reminderIds = dataStore.reminders.filter { petIds.contains($0.petId ?? UUID()) }.map { $0.id }

        let instances = dataStore.reminderInstances
            .filter { instance in
                reminderIds.contains(instance.reminderId ?? UUID()) &&
                instance.scheduledAt >= start && instance.scheduledAt <= .now
            }

        let completed = instances.filter { $0.statusRaw == "completed" }.count
        let total = instances.count
        let pct = total == 0 ? 0 : Int(round(Double(completed) / Double(total) * 100))

        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("30-day adherence")
                    .font(PawlyFont.caption)
                    .foregroundStyle(PawlyColors.slate)
                Text("\(pct)%")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(PawlyColors.ink)
            }
            Spacer()
            Text("\(completed)/\(total) done")
                .font(PawlyFont.bodyMedium)
                .foregroundStyle(PawlyColors.slate)
        }
        .padding(Spacing.m)
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(PawlyColors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .stroke(PawlyColors.sand.opacity(0.4), lineWidth: 0.75)
        )
        .padding(.horizontal, Spacing.screenHorizontal)
        .padding(.vertical, Spacing.s)
    }
}

private struct DayID: Identifiable, Hashable {
    var date: Date
    var id: Date { date }
}

// MARK: - Add Reminder Picker

private struct AddReminderPickerViewDTO: View {
    let dataStore: DataStore
    @Binding var filterPetID: UUID?
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPetID: UUID?
    @State private var showingReminderEdit = false

    private var selectedPet: PetDTO? {
        dataStore.pets.first { $0.id == selectedPetID }
    }

    var body: some View {
        NavigationStack {
            List {
                if dataStore.pets.isEmpty {
                    Section {
                        Text("No pets available. Add a pet first.")
                            .foregroundStyle(PawlyColors.slate)
                    }
                } else {
                    Section("Select a pet") {
                        ForEach(dataStore.pets) { pet in
                            Button {
                                selectedPetID = pet.id
                                filterPetID = pet.id
                                showingReminderEdit = true
                            } label: {
                                HStack {
                                    PetAvatarDTO(pet: pet, size: 40)
                                    Text(pet.name)
                                        .font(PawlyFont.bodyMedium)
                                        .foregroundStyle(PawlyColors.ink)
                                    Spacer()
                                    if selectedPetID == pet.id {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(PawlyColors.forest)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle("Add Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .sheet(isPresented: $showingReminderEdit) {
            if let pet = selectedPet {
                ReminderEditViewDTO(pet: pet, existing: nil)
            }
        }
    }
}

// MARK: - Month Grid

struct MonthGridDTO: View {
    let anchor: Date
    let dataStore: DataStore
    let filterPetID: UUID?
    var onTapDay: (Date) -> Void

    private let cal = Calendar.current
    private let weekdayHeaders = ["S", "M", "T", "W", "T", "F", "S"]

    private var filteredPetIds: [UUID] {
        filterPetID != nil ? [filterPetID!] : dataStore.pets.map { $0.id }
    }

    var body: some View {
        VStack(spacing: Spacing.xs) {
            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { i in
                    Text(weekdayHeaders[i])
                        .font(PawlyFont.caption)
                        .foregroundStyle(PawlyColors.slate)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 4)

            let cells = computeCells()
            let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(Array(cells.enumerated()), id: \.offset) { _, cell in
                    if let day = cell {
                        DayCellDTO(day: day, statuses: statuses(for: day), isToday: cal.isDateInToday(day))
                            .onTapGesture { onTapDay(day) }
                    } else {
                        Color.clear.frame(height: 52)
                    }
                }
            }
        }
    }

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

    private func statuses(for day: Date) -> [String] {
        let dayStart = day.startOfDay
        let dayEnd = day.endOfDay

        let reminderIds = dataStore.reminders
            .filter { filteredPetIds.contains($0.petId ?? UUID()) }
            .map { $0.id }

        return dataStore.reminderInstances
            .filter { instance in
                reminderIds.contains(instance.reminderId ?? UUID()) &&
                instance.scheduledAt >= dayStart && instance.scheduledAt <= dayEnd
            }
            .map { inst -> String in
                if inst.statusRaw == "completed" { return "completed" }
                if inst.statusRaw == "upcoming", inst.scheduledAt < .now { return "missed" }
                return inst.statusRaw
            }
    }
}

private struct DayCellDTO: View {
    let day: Date
    let statuses: [String]
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
        .frame(maxWidth: .infinity, minHeight: 52)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func dotView(for status: String) -> some View {
        switch status {
        case "completed":
            StatusDot(status: .completed, size: 7)
        case "upcoming", "snoozed":
            StatusDot(status: .upcoming, size: 7)
        case "missed":
            StatusDot(status: .missed, size: 7)
        case "skipped":
            StatusDot(status: .upcoming, size: 7).opacity(0.5)
        default:
            StatusDot(status: .upcoming, size: 7)
        }
    }
}

// MARK: - Week Timeline

struct WeekTimelineViewDTO: View {
    let anchor: Date
    let dataStore: DataStore
    let filterPetID: UUID?

    private let cal = Calendar.current

    private var weekDays: [Date] {
        let start = cal.dateInterval(of: .weekOfYear, for: anchor)?.start ?? anchor
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: start) }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.s) {
                ForEach(weekDays, id: \.self) { day in
                    DayColumnDTO(day: day, dataStore: dataStore, filterPetID: filterPetID)
                }
            }
            .padding(.vertical, Spacing.m)
        }
    }
}

private struct DayColumnDTO: View {
    let day: Date
    let dataStore: DataStore
    let filterPetID: UUID?

    private var instances: [ReminderInstanceDTO] {
        let start = day.startOfDay
        let end = day.endOfDay

        let petIds = filterPetID != nil ? [filterPetID!] : dataStore.pets.map { $0.id }
        let reminderIds = dataStore.reminders
            .filter { petIds.contains($0.petId ?? UUID()) }
            .map { $0.id }

        return dataStore.reminderInstances
            .filter { instance in
                reminderIds.contains(instance.reminderId ?? UUID()) &&
                instance.scheduledAt >= start && instance.scheduledAt <= end
            }
            .sorted { $0.scheduledAt < $1.scheduledAt }
    }

    var body: some View {
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
                            .frame(width: 52, alignment: .leading)
                        if let reminder = dataStore.reminders.first(where: { $0.id == inst.reminderId }),
                           let type = ReminderType(rawValue: reminder.typeRaw) {
                            Image(systemName: type.sfSymbol)
                                .font(.system(size: 14))
                                .foregroundStyle(PawlyColors.forest)
                        }
                        if let reminder = dataStore.reminders.first(where: { $0.id == inst.reminderId }) {
                            Text(reminder.title)
                                .font(PawlyFont.bodyMedium)
                                .foregroundStyle(PawlyColors.ink)
                        }
                        Spacer()
                        StatusDot(status: statusFor(inst), size: 8)
                    }
                }
            }
        }
        .padding(Spacing.s)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Radius.small, style: .continuous)
                .fill(PawlyColors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.small, style: .continuous)
                .stroke(PawlyColors.sand.opacity(0.4), lineWidth: 0.75)
        )
    }

    private func statusFor(_ inst: ReminderInstanceDTO) -> StatusDot.Status {
        switch inst.statusRaw {
        case "completed": return .completed
        case "upcoming", "snoozed":
            return inst.scheduledAt < .now ? .missed : .upcoming
        case "missed": return .missed
        case "skipped": return .upcoming
        default: return .upcoming
        }
    }
}

// MARK: - Day Detail Sheet

struct DayDetailSheetDTO: View {
    let day: Date
    let dataStore: DataStore
    let filterPetID: UUID?

    private var timeline: [ReminderInstanceDTO] {
        let start = day.startOfDay
        let end = day.endOfDay

        let petIds = filterPetID != nil ? [filterPetID!] : dataStore.pets.map { $0.id }
        let reminderIds = dataStore.reminders
            .filter { petIds.contains($0.petId ?? UUID()) }
            .map { $0.id }

        return dataStore.reminderInstances
            .filter { instance in
                reminderIds.contains(instance.reminderId ?? UUID()) &&
                instance.scheduledAt >= start && instance.scheduledAt <= end
            }
            .sorted { $0.scheduledAt < $1.scheduledAt }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s) {
                    if timeline.isEmpty {
                        VStack(spacing: Spacing.s) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(PawlyColors.sage)
                            Text("No reminders for this day.")
                                .font(PawlyFont.bodyMedium)
                                .foregroundStyle(PawlyColors.slate)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.xl)
                    } else {
                        ForEach(timeline) { inst in
                            TimelineRowDTO(instance: inst, dataStore: dataStore) {
                                toggle(inst)
                            }
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

    private func toggle(_ inst: ReminderInstanceDTO) {
        Haptics.success()
        Task { await dataStore.toggleReminderInstance(inst) }
    }
}

private struct TimelineRowDTO: View {
    let instance: ReminderInstanceDTO
    let dataStore: DataStore
    var onToggle: () -> Void

    private var reminder: ReminderDTO? {
        dataStore.reminders.first { $0.id == instance.reminderId }
    }

    private var pet: PetDTO? {
        if let reminder = reminder, let petId = reminder.petId {
            return dataStore.pets.first { $0.id == petId }
        }
        return nil
    }

    var body: some View {
        HStack(spacing: Spacing.m) {
            Text(instance.scheduledAt, format: .dateTime.hour().minute())
                .font(PawlyFont.tabularSmall)
                .foregroundStyle(PawlyColors.slate)
                .frame(width: 52, alignment: .leading)

            if let typeRaw = reminder?.typeRaw,
               let type = ReminderType(rawValue: typeRaw) {
                Image(systemName: type.sfSymbol)
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: pet?.accentHex ?? "#2D5F4E"))
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(PawlyColors.forestLight))
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(reminder?.title ?? "Reminder")
                    .font(PawlyFont.bodyLarge)
                    .foregroundStyle(PawlyColors.ink)
                if let pet = pet {
                    Text(pet.name)
                        .font(PawlyFont.caption)
                        .foregroundStyle(PawlyColors.slate)
                }
            }

            Spacer()

            Button(action: onToggle) {
                Image(systemName: instance.statusRaw == "completed"
                      ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundStyle(instance.statusRaw == "completed" ? PawlyColors.forest : PawlyColors.sand)
            }
            .buttonStyle(.plain)
        }
        .padding(Spacing.s)
        .background(
            RoundedRectangle(cornerRadius: Radius.small, style: .continuous)
                .fill(PawlyColors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.small, style: .continuous)
                .stroke(PawlyColors.sand.opacity(0.4), lineWidth: 0.75)
        )
    }
}

#Preview("Calendar") {
    CalendarView()
        .environmentObject(PetContextStore())
        .environmentObject(DataStore.shared)
}