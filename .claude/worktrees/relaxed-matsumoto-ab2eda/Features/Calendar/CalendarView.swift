import SwiftUI

/// Calendar tab — clean month/week view with restrained styling.
/// Less border noise. More whitespace. Purposeful status dots.
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
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack(alignment: .center, spacing: Spacing.s) {
                    Button {
                        Haptics.light()
                        withAnimation(Motion.transition) { anchor = shift(by: -1) }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(PawlyColors.ink)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(PawlyColors.surface))
                    }
                    .buttonStyle(.plain)

                    Text(headerTitle)
                        .font(PawlyFont.headingMedium)
                        .foregroundStyle(PawlyColors.ink)
                        .frame(maxWidth: .infinity)

                    Button {
                        Haptics.light()
                        withAnimation(Motion.transition) { anchor = shift(by: 1) }
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(PawlyColors.ink)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(PawlyColors.surface))
                    }
                    .buttonStyle(.plain)

                    // Mode toggle
                    HStack(spacing: 0) {
                        modeButton(.month, label: "Month")
                        modeButton(.week,  label: "Week")
                    }
                    .padding(3)
                    .background(
                        Capsule().fill(PawlyColors.surface)
                    )
                    .overlay(
                        Capsule().stroke(PawlyColors.hairline, lineWidth: 0.75)
                    )
                }
                .padding(.horizontal, Spacing.screenHorizontal)
                .padding(.top, Spacing.m)
                .padding(.bottom, Spacing.m)

                // Pet filter
                petFilterRow
                    .padding(.bottom, Spacing.m)

                // Calendar content
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
                                    withAnimation(Motion.transition) { mode = .week }
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
                                        withAnimation(Motion.transition) { mode = .month }
                                    }
                                }
                        )
                }

                // Adherence
                adherenceRow
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .padding(.top, Spacing.xl)

                Color.clear.frame(height: Spacing.xxl)
            }
        }
        .background(PawlyColors.canvas.ignoresSafeArea())
        .scrollIndicators(.hidden)
        .navigationTitle("")
        .navigationBarHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Haptics.light()
                    showingAddReminder = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(PawlyColors.forest)
                }
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

    @ViewBuilder
    private func modeButton(_ m: Mode, label: String) -> some View {
        Button {
            Haptics.light()
            withAnimation(Motion.snap) { mode = m }
        } label: {
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(mode == m ? .white : PawlyColors.slate)
                .frame(width: 52, height: 28)
                .background(
                    Capsule().fill(mode == m ? PawlyColors.forest : .clear)
                )
        }
        .buttonStyle(.plain)
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

    private var petFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
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
    }

    @ViewBuilder
    private func chip(_ label: String, color: Color, active: Bool, onTap: @escaping () -> Void) -> some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Circle().fill(color).frame(width: 6, height: 6)
                Text(label).font(.system(size: 12, weight: .semibold))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Capsule().fill(active ? color.opacity(0.12) : PawlyColors.surface)
            )
            .overlay(
                Capsule().stroke(active ? color.opacity(0.3) : PawlyColors.hairline,
                                 lineWidth: active ? 1 : 0.75)
            )
            .foregroundStyle(active ? color : PawlyColors.slate)
        }
        .buttonStyle(.plain)
    }

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

        return HStack(spacing: Spacing.m) {
            ZStack {
                Circle()
                    .stroke(PawlyColors.forestSoft, lineWidth: 5)
                    .frame(width: 56, height: 56)
                Circle()
                    .trim(from: 0, to: CGFloat(pct) / 100)
                    .stroke(PawlyColors.forest, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .frame(width: 56, height: 56)
                    .rotationEffect(.degrees(-90))
                Text("\(pct)%")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(PawlyColors.forest)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("30-day adherence")
                    .font(PawlyFont.captionSmall)
                    .foregroundStyle(PawlyColors.slate)
                    .textCase(.uppercase)
                Text("\(completed) of \(total) reminders done")
                    .font(PawlyFont.bodyMedium)
                    .foregroundStyle(PawlyColors.ink)
            }
            Spacer()
        }
        .padding(Spacing.m)
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(PawlyColors.surface)
        )
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
        VStack(spacing: 8) {
            // Weekday headers
            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { i in
                    Text(weekdayHeaders[i])
                        .font(PawlyFont.captionSmall)
                        .foregroundStyle(PawlyColors.slate.opacity(0.7))
                        .frame(maxWidth: .infinity)
                }
            }

            let cells = computeCells()
            let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(Array(cells.enumerated()), id: \.offset) { _, cell in
                    if let day = cell {
                        Button {
                            onTapDay(day)
                        } label: {
                            DayCellDTO(day: day, statuses: statuses(for: day), isToday: cal.isDateInToday(day))
                        }
                        .buttonStyle(.plain)
                    } else {
                        Color.clear.frame(height: 48)
                    }
                }
            }
        }
        .padding(Spacing.m)
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(PawlyColors.surface)
        )
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
                .font(.system(size: 14, weight: isToday ? .bold : .medium, design: .rounded))
                .foregroundStyle(isToday ? Color.white : PawlyColors.ink)
                .frame(width: 28, height: 28)
                .background(
                    Circle().fill(isToday ? PawlyColors.forest : Color.clear)
                )

            HStack(spacing: 2) {
                ForEach(0..<min(3, statuses.count), id: \.self) { i in
                    dotView(for: statuses[i])
                }
                if statuses.count > 3 {
                    Text("+")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(PawlyColors.slate.opacity(0.5))
                }
                if statuses.isEmpty {
                    Color.clear.frame(height: 5)
                }
            }
            .frame(height: 5)
        }
        .frame(maxWidth: .infinity, minHeight: 46)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func dotView(for status: String) -> some View {
        switch status {
        case "completed":
            Circle().fill(PawlyColors.sage).frame(width: 5, height: 5)
        case "upcoming", "snoozed":
            Circle().fill(PawlyColors.forest.opacity(0.5)).frame(width: 5, height: 5)
        case "missed":
            Circle().fill(PawlyColors.alert).frame(width: 5, height: 5)
        case "skipped":
            Circle().fill(PawlyColors.slate.opacity(0.3)).frame(width: 5, height: 5)
        default:
            Circle().fill(PawlyColors.forest.opacity(0.3)).frame(width: 5, height: 5)
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
        VStack(spacing: Spacing.s) {
            ForEach(weekDays, id: \.self) { day in
                DayColumnDTO(day: day, dataStore: dataStore, filterPetID: filterPetID)
            }
        }
    }
}

private struct DayColumnDTO: View {
    let day: Date
    let dataStore: DataStore
    let filterPetID: UUID?

    @State private var showingDaySheet = false

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
                .font(PawlyFont.headingSmall)
                .foregroundStyle(PawlyColors.ink)
            if instances.isEmpty {
                Text("No reminders")
                    .font(PawlyFont.captionSmall)
                    .foregroundStyle(PawlyColors.slate.opacity(0.6))
            } else {
                VStack(spacing: 8) {
                    ForEach(instances) { inst in
                        HStack(spacing: Spacing.s) {
                            Text(inst.scheduledAt, format: .dateTime.hour().minute())
                                .font(PawlyFont.tabularSmall)
                                .foregroundStyle(PawlyColors.slate)
                                .frame(width: 52, alignment: .leading)
                            if let reminder = dataStore.reminders.first(where: { $0.id == inst.reminderId }),
                               let type = ReminderType(rawValue: reminder.typeRaw) {
                                Image(systemName: type.sfSymbol)
                                    .font(.system(size: 13))
                                    .foregroundStyle(PawlyColors.forest)
                            }
                            if let reminder = dataStore.reminders.first(where: { $0.id == inst.reminderId }) {
                                Text(reminder.title)
                                    .font(PawlyFont.bodyMedium)
                                    .foregroundStyle(PawlyColors.ink)
                            }
                            Spacer()
                            StatusDot(status: statusFor(inst), size: 7)
                        }
                    }
                }
            }
        }
        .padding(Spacing.s)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Radius.input, style: .continuous)
                .fill(PawlyColors.surface)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            Haptics.light()
            showingDaySheet = true
        }
        .sheet(isPresented: $showingDaySheet) {
            DayDetailSheetDTO(day: day, dataStore: dataStore, filterPetID: filterPetID)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
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

    @State private var showingAddNote = false
    @State private var showingAddReminder = false

    private var petIds: [UUID] {
        filterPetID != nil ? [filterPetID!] : dataStore.pets.map { $0.id }
    }

    private var timeline: [ReminderInstanceDTO] {
        let start = day.startOfDay
        let end = day.endOfDay
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

    private var notes: [DayNoteDTO] {
        dataStore.dayNotes(forDay: day, petId: filterPetID)
    }

    private var hasContent: Bool {
        !timeline.isEmpty || !notes.isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.m) {
                    // Reminders section
                    if !timeline.isEmpty {
                        VStack(alignment: .leading, spacing: Spacing.s) {
                            Text("Reminders")
                                .font(PawlyFont.headingSmall)
                                .foregroundStyle(PawlyColors.ink)
                            ForEach(timeline) { inst in
                                TimelineRowDTO(instance: inst, dataStore: dataStore) {
                                    toggle(inst)
                                }
                            }
                        }
                    }

                    // Notes section
                    if !notes.isEmpty {
                        VStack(alignment: .leading, spacing: Spacing.s) {
                            Text("Notes")
                                .font(PawlyFont.headingSmall)
                                .foregroundStyle(PawlyColors.ink)
                            ForEach(notes) { note in
                                NoteRowDTO(note: note, pet: dataStore.pets.first { $0.id == note.petId })
                            }
                        }
                    }

                    // Empty state with CTAs
                    if !hasContent {
                        VStack(spacing: Spacing.m) {
                            ZStack {
                                Circle().fill(PawlyColors.sageSoft).frame(width: 64, height: 64)
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 28))
                                    .foregroundStyle(PawlyColors.sage)
                            }
                            Text("Nothing scheduled")
                                .font(PawlyFont.headingMedium)
                                .foregroundStyle(PawlyColors.ink)
                            Text("Enjoy a calm day with your pet.")
                                .font(PawlyFont.bodyMedium)
                                .foregroundStyle(PawlyColors.slate)

                            HStack(spacing: Spacing.s) {
                                Button {
                                    Haptics.light()
                                    showingAddNote = true
                                } label: {
                                    Label("Add Note", systemImage: "note.text")
                                }
                                .buttonStyle(.pawlySecondary(compact: true))

                                Button {
                                    Haptics.light()
                                    showingAddReminder = true
                                } label: {
                                    Label("Add Reminder", systemImage: "bell.badge")
                                }
                                .buttonStyle(.pawlyPrimary(compact: true))
                            }
                            .padding(.top, Spacing.s)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.xl)
                    } else {
                        // Add buttons at bottom when there is content
                        HStack(spacing: Spacing.s) {
                            Button {
                                Haptics.light()
                                showingAddNote = true
                            } label: {
                                Label("Add Note", systemImage: "note.text")
                            }
                            .buttonStyle(.pawlySecondary(compact: true))

                            Button {
                                Haptics.light()
                                showingAddReminder = true
                            } label: {
                                Label("Add Reminder", systemImage: "bell.badge")
                            }
                            .buttonStyle(.pawlyPrimary(compact: true))
                        }
                        .padding(.top, Spacing.s)
                    }
                }
                .padding(.horizontal, Spacing.screenHorizontal)
                .padding(.top, Spacing.m)
                .padding(.bottom, Spacing.xxl)
            }
            .background(PawlyColors.canvas.ignoresSafeArea())
            .navigationTitle(day.formatted(.dateTime.weekday(.wide).day().month(.wide)))
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingAddNote) {
            AddNoteSheetDTO(day: day, dataStore: dataStore, filterPetID: filterPetID)
        }
        .sheet(isPresented: $showingAddReminder) {
            AddReminderPickerViewDTO(dataStore: dataStore, filterPetID: .constant(filterPetID))
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
                ZStack {
                    Circle().fill(PawlyColors.forestSoft).frame(width: 32, height: 32)
                    Image(systemName: type.sfSymbol)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(hex: pet?.accentHex ?? "#1F4E40"))
                }
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(reminder?.title ?? "Reminder")
                    .font(PawlyFont.bodyLarge.weight(.semibold))
                    .foregroundStyle(PawlyColors.ink)
                if let pet = pet {
                    Text(pet.name)
                        .font(PawlyFont.captionSmall)
                        .foregroundStyle(PawlyColors.slate)
                }
            }

            Spacer()

            Button(action: onToggle) {
                Image(systemName: instance.statusRaw == "completed"
                      ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 26))
                    .foregroundStyle(instance.statusRaw == "completed" ? PawlyColors.forest : PawlyColors.slate.opacity(0.3))
            }
            .buttonStyle(.plain)
        }
        .padding(Spacing.s)
        .background(
            RoundedRectangle(cornerRadius: Radius.input, style: .continuous)
                .fill(PawlyColors.surface)
        )
    }
}

// MARK: - Note Row

private struct NoteRowDTO: View {
    let note: DayNoteDTO
    let pet: PetDTO?

    var body: some View {
        HStack(spacing: Spacing.m) {
            ZStack {
                Circle().fill(PawlyColors.peachSoft).frame(width: 32, height: 32)
                Image(systemName: "note.text")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(PawlyColors.peach)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(note.body)
                    .font(PawlyFont.bodyMedium)
                    .foregroundStyle(PawlyColors.ink)
                    .lineLimit(3)
                if let pet = pet {
                    Text(pet.name)
                        .font(PawlyFont.captionSmall)
                        .foregroundStyle(PawlyColors.slate)
                }
            }

            Spacer()
        }
        .padding(Spacing.s)
        .background(
            RoundedRectangle(cornerRadius: Radius.input, style: .continuous)
                .fill(PawlyColors.surface)
        )
    }
}

// MARK: - Add Note Sheet

private struct AddNoteSheetDTO: View {
    let day: Date
    let dataStore: DataStore
    let filterPetID: UUID?

    @Environment(\.dismiss) private var dismiss
    @State private var bodyText: String = ""
    @State private var selectedPetID: UUID?

    private var targetPetID: UUID? {
        if let filterPetID {
            return filterPetID
        }
        return selectedPetID
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.m) {
                    if filterPetID == nil {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Pet").font(PawlyFont.caption).foregroundStyle(PawlyColors.slate)
                            Picker("Pet", selection: $selectedPetID) {
                                Text("Select a pet").tag(UUID?.none)
                                ForEach(dataStore.pets) { pet in
                                    Text(pet.name).tag(Optional(pet.id))
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(PawlyColors.forest)
                        }
                    }

                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Note").font(PawlyFont.caption).foregroundStyle(PawlyColors.slate)
                        TextEditor(text: $bodyText)
                            .frame(minHeight: 120)
                            .padding(Spacing.s)
                            .background(
                                RoundedRectangle(cornerRadius: Radius.input)
                                    .fill(PawlyColors.surface)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: Radius.input)
                                    .stroke(PawlyColors.sand, lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, Spacing.screenHorizontal)
                .padding(.vertical, Spacing.l)
            }
            .background(PawlyColors.canvas.ignoresSafeArea())
            .navigationTitle("Add Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            if let petId = targetPetID {
                                await dataStore.createDayNote(forPetId: petId, day: day, body: bodyText.trimmingCharacters(in: .whitespacesAndNewlines))
                            }
                            dismiss()
                        }
                    }
                    .disabled((targetPetID == nil) || bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .tint(PawlyColors.forest)
                }
            }
        }
    }
}

#Preview("Calendar") {
    NavigationStack { CalendarView() }
        .environmentObject(PetContextStore())
        .environmentObject(DataStore.shared)
}
