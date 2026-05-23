import SwiftUI

// MARK: - Home View

struct HomeView: View {
    @EnvironmentObject var petContext: PetContextStore
    @EnvironmentObject var dataStore: DataStore

    @State private var showingMoodPicker = false
    @State private var quickLogKind: LogKind?
    @State private var editingReminder: ReminderDTO?

    var activePet: PetDTO? {
        dataStore.pets.first { $0.id == petContext.activePetID } ?? dataStore.pets.first
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                headerSection
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .padding(.top, Spacing.m)
                    .padding(.bottom, Spacing.l)

                if let pet = activePet {
                    PetSelectorRow(pets: dataStore.pets, selectedId: petContext.activePetID) { newId in
                        petContext.setActive(dataStore.pets.first { $0.id == newId }!)
                    } onAdd: {}
                    .padding(.horizontal, Spacing.screenHorizontal)

                    HomeStreakBar(
                        streak: dataStore.streakDays(forPetId: pet.id),
                        days: dataStore.weekActivityDots(forPetId: pet.id)
                    )
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .padding(.top, Spacing.m)

                    WellnessHeroCard(
                        pet: pet,
                        wellnessPercent: dataStore.wellnessPercent(forPetId: pet.id),
                        mood: dataStore.latestMood(forPetId: pet.id),
                        mealsToday: dataStore.todayLogCount(forPetId: pet.id, kind: .meal),
                        walksToday: dataStore.todayLogCount(forPetId: pet.id, kind: .walk),
                        medsTakenToday: medsTakenToday(forPetId: pet.id),
                        onMoodTap: { showingMoodPicker = true }
                    )
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .padding(.top, Spacing.m)

                    QuickLogSection { kind in
                        quickLogKind = kind
                    }
                    .padding(.top, Spacing.xl)

                    TodayChecklistSection(pet: pet)
                        .padding(.top, Spacing.xl)

                    UpcomingWeekSection(pet: pet) { reminder in
                        editingReminder = reminder
                    }
                    .padding(.top, Spacing.xl)

                    RecentActivitySection(pet: pet)
                        .padding(.top, Spacing.xl)

                    PetInfoCard(pet: pet)
                        .padding(.horizontal, Spacing.screenHorizontal)
                        .padding(.top, Spacing.xl)

                    PawMDHomeCard(petName: pet.name)
                        .padding(.horizontal, Spacing.screenHorizontal)
                        .padding(.top, Spacing.xl)

                    Spacer(minLength: Spacing.tabBarBottomSafe)
                } else {
                    emptyState
                        .padding(.horizontal, Spacing.screenHorizontal)
                }
            }
        }
        .background(PawlyColors.pastelBg.ignoresSafeArea())
        .scrollIndicators(.hidden)
        .refreshable { await dataStore.fetchAllData() }
        .sheet(isPresented: $showingMoodPicker) {
            if let pet = activePet {
                MoodPickerSheet(
                    petName: pet.name,
                    current: dataStore.latestMood(forPetId: pet.id)
                ) { mood in
                    Task {
                        await dataStore.createMoodEntry(forPetId: pet.id, mood: mood)
                    }
                }
            }
        }
        .sheet(item: $quickLogKind) { kind in
            QuickLogSheet(initialKind: kind)
        }
        .sheet(item: $editingReminder) { reminder in
            if let pet = activePet {
                ReminderEditViewDTO(pet: pet, existing: reminder)
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(dateString.uppercased())
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(PawlyColors.inkSoft)
                .tracking(0.5)
            Text(greeting)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(PawlyColors.ink)
                .tracking(-0.01)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var greeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        if h < 12 { return "Good morning," }
        if h < 17 { return "Good afternoon," }
        return "Good evening,"
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: Date())
    }

    private func medsTakenToday(forPetId petId: UUID) -> Int {
        let medReminderIds = Set(
            dataStore.reminders
                .filter { $0.petId == petId && ReminderType(rawValue: $0.typeRaw) == .medication }
                .map(\.id)
        )
        return dataStore.reminderInstancesToday(forPetId: petId)
            .filter { instance in
                guard let rid = instance.reminderId else { return false }
                return medReminderIds.contains(rid) && instance.statusRaw == "completed"
            }
            .count
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.m) {
            ZStack {
                Circle()
                    .fill(PawlyColors.navySoft)
                    .frame(width: 80, height: 80)
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(PawlyColors.navy)
            }
            VStack(spacing: 6) {
                Text("No pets yet")
                    .font(PawlyFont.headingLarge)
                    .foregroundStyle(PawlyColors.ink)
                Text("Add your first pet to get started.")
                    .font(PawlyFont.bodyMedium)
                    .foregroundStyle(PawlyColors.slate)
            }
        }
        .padding(.vertical, Spacing.xxl)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Pet Selector Row

struct PetSelectorRow: View {
    let pets: [PetDTO]
    let selectedId: UUID?
    let onSelect: (UUID) -> Void
    let onAdd: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(pets) { pet in
                    PetSelectorChip(
                        pet: pet,
                        isSelected: pet.id == selectedId
                    ) {
                        onSelect(pet.id)
                    }
                }
                AddPetChipButton(action: onAdd)
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - Wellness Hero Card

struct WellnessHeroCard: View {
    let pet: PetDTO
    let wellnessPercent: Int?
    let mood: Mood?
    let mealsToday: Int
    let walksToday: Int
    let medsTakenToday: Int
    let onMoodTap: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            WellnessRingView(
                value: wellnessPercent,
                accent: Color(hex: pet.accentHex)
            )
            .frame(width: 146, height: 146)

            VStack(alignment: .leading, spacing: 0) {
                Text("\(pet.name) feels")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(PawlyColors.inkSoft)
                    .tracking(0.8)
                    .textCase(.uppercase)

                Button(action: onMoodTap) {
                    HStack(spacing: 6) {
                        Text(mood?.label ?? "Set mood")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(PawlyColors.ink)
                            .tracking(-0.01)
                        Text(mood?.emoji ?? "🐾")
                            .font(.system(size: 18))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(PawlyColors.inkSoft)
                    }
                    .padding(.top, 2)
                }
                .buttonStyle(.plain)

                Spacer(minLength: 8)

                VStack(spacing: 6) {
                    countRow("Meals", value: mealsToday, color: PawlyColors.wellnessNutrition)
                    countRow("Walks", value: walksToday, color: PawlyColors.wellnessActivity)
                    countRow("Meds taken", value: medsTakenToday, color: PawlyColors.wellnessHydration)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: Radius.cardLg, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: pet.accentHex).opacity(0.15), PawlyColors.pastelSurface2],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
    }

    private func countRow(_ label: String, value: Int, color: Color) -> some View {
        HStack(spacing: 8) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(PawlyColors.inkSoft)
            Spacer()
            Text("\(value)")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(PawlyColors.ink)
        }
    }
}

/// Wellness ring that honestly reflects today's reminder completion.
/// If there are no tasks today, shows an empty ring with a "—" placeholder.
private struct WellnessRingView: View {
    let value: Int?
    let accent: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.black.opacity(0.06), lineWidth: 11)
            Circle()
                .trim(from: 0, to: CGFloat(value ?? 0) / 100.0)
                .stroke(accent, style: StrokeStyle(lineWidth: 11, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.35), value: value ?? 0)
            VStack(spacing: 2) {
                if let value {
                    Text("\(value)%")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(PawlyColors.ink)
                    Text("done today")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(PawlyColors.inkSoft)
                        .tracking(0.4)
                } else {
                    Text("—")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(PawlyColors.inkSoft)
                    Text("no tasks today")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(PawlyColors.inkSoft)
                        .tracking(0.4)
                }
            }
        }
    }
}

// MARK: - Mood Picker Sheet

struct MoodPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let petName: String
    let current: Mood?
    let onSelect: (Mood) -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: Spacing.m) {
                Text("How is \(petName) feeling?")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(PawlyColors.ink)
                    .padding(.top, Spacing.s)
                Text("Tap a mood to update.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(PawlyColors.inkSoft)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(Mood.allCases) { mood in
                        Button {
                            Haptics.success()
                            onSelect(mood)
                            dismiss()
                        } label: {
                            VStack(spacing: 6) {
                                Text(mood.emoji).font(.system(size: 34))
                                Text(mood.label)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(PawlyColors.ink)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: Radius.cardLg, style: .continuous)
                                    .fill(current == mood ? PawlyColors.peachAccentSoft : Color.white)
                                    .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: Radius.cardLg, style: .continuous)
                                    .stroke(current == mood ? PawlyColors.peachAccent : .clear, lineWidth: 2)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, Spacing.s)

                Spacer()
            }
            .padding(.horizontal, Spacing.screenHorizontal)
            .background(PawlyColors.pastelBg.ignoresSafeArea())
            .navigationTitle("Update mood")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Today's Checklist

struct TodayChecklistSection: View {
    let pet: PetDTO
    @EnvironmentObject var dataStore: DataStore

    private var todayInstances: [ReminderInstanceDTO] {
        dataStore.reminderInstancesToday(forPetId: pet.id)
    }

    private var checklist: [ChecklistItem] {
        todayInstances.map { instance in
            let reminder = dataStore.reminders.first { $0.id == instance.reminderId }
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "h:mm a"
            return ChecklistItem(
                id: instance.id.uuidString,
                label: reminder?.title ?? "Task",
                icon: ReminderType(rawValue: reminder?.typeRaw ?? "")?.sfSymbol ?? "bell.fill",
                time: timeFormatter.string(from: instance.scheduledAt),
                done: instance.statusRaw == "completed",
                tone: toneFor(reminder?.typeRaw ?? "")
            )
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Today's care")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(PawlyColors.ink)
                Spacer()
                Text("\(completedCount)/\(checklist.count)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(PawlyColors.inkSoft)
            }
            .padding(.horizontal, Spacing.screenHorizontal)

            if checklist.isEmpty {
                emptyChecklist
            } else {
                VStack(spacing: 8) {
                    ForEach(checklist) { item in
                        ChecklistRow(item: item) {
                            toggle(item)
                        }
                    }
                }
                .padding(.horizontal, Spacing.screenHorizontal)
            }
        }
    }

    private var completedCount: Int {
        checklist.filter { $0.done }.count
    }

    private func toggle(_ item: ChecklistItem) {
        guard let instance = todayInstances.first(where: { $0.id.uuidString == item.id }) else { return }
        Haptics.success()
        Task { await dataStore.toggleReminderInstance(instance) }
    }

    private func toneFor(_ typeRaw: String) -> Int {
        switch typeRaw {
        case "medication": return 6
        case "vaccination": return 4
        case "dewormingTickFlea": return 3
        case "vetCheckup": return 2
        case "grooming": return 5
        case "weightCheck": return 1
        default: return 0
        }
    }

    private var emptyChecklist: some View {
        VStack(spacing: 8) {
            Image(systemName: "checklist")
                .font(.system(size: 24))
                .foregroundStyle(PawlyColors.inkSoft.opacity(0.3))
            Text("No tasks for today")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(PawlyColors.inkSoft)
            Text("Go to the Track tab → tap “Add” to create medication or vet reminders.")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(PawlyColors.inkSoft.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.m)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: Radius.cardLg, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)
        )
        .padding(.horizontal, Spacing.screenHorizontal)
    }
}

struct ChecklistItem: Identifiable {
    let id: String
    let label: String
    let icon: String
    let time: String
    var done: Bool
    let tone: Int
}

struct ChecklistRow: View {
    let item: ChecklistItem
    let onToggle: () -> Void

    private var cardTone: PawlyColors.CardTone {
        PawlyColors.CardTone(rawValue: item.tone % 7) ?? .peach
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(item.done ? Color(hex: "#F0EBE2") : cardTone.bg)
                    .frame(width: 38, height: 38)
                Image(systemName: item.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(item.done ? PawlyColors.inkMuted : cardTone.tint)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.label)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(PawlyColors.ink)
                    .strikethrough(item.done, color: PawlyColors.inkMuted)
                Text(item.time)
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundStyle(PawlyColors.inkSoft)
            }

            Spacer()

            Button(action: onToggle) {
                ZStack {
                    Circle()
                        .fill(item.done ? PawlyColors.peachAccent : .clear)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Circle()
                                .stroke(item.done ? .clear : Color.black.opacity(0.15), lineWidth: 2)
                        )
                    if item.done {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .buttonStyle(.plain)
            .animation(.spring(response: 0.28, dampingFraction: 0.6), value: item.done)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: Radius.cardLg, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
        )
        .opacity(item.done ? 0.65 : 1)
    }
}

// MARK: - Quick Log Section

/// Four big tap-to-log tiles. Each opens QuickLogSheet pre-set to that kind.
struct QuickLogSection: View {
    let onTap: (LogKind) -> Void

    private struct Tile {
        let kind: LogKind
        let label: String
        let icon: String
        let bg: Color
        let tint: Color
    }

    private var tiles: [Tile] {
        [
            Tile(kind: .meal,    label: "Meal",    icon: "fork.knife",  bg: PawlyColors.CardTone.sage.bg,    tint: PawlyColors.wellnessNutrition),
            Tile(kind: .walk,    label: "Walk",    icon: "figure.walk", bg: PawlyColors.CardTone.sky.bg,     tint: PawlyColors.wellnessActivity),
            Tile(kind: .hygiene, label: "Hygiene", icon: "drop.fill",   bg: PawlyColors.CardTone.lavender.bg, tint: PawlyColors.lavender),
            Tile(kind: .weight,  label: "Weight",  icon: "scalemass",   bg: PawlyColors.CardTone.peach.bg,   tint: PawlyColors.peachAccent),
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Quick log")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(PawlyColors.ink)
                Spacer()
                Text("Tap to log instantly")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(PawlyColors.inkSoft)
            }
            .padding(.horizontal, Spacing.screenHorizontal)

            HStack(spacing: 10) {
                ForEach(Array(tiles.enumerated()), id: \.offset) { _, tile in
                    Button {
                        Haptics.light()
                        onTap(tile.kind)
                    } label: {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle().fill(Color.white).frame(width: 38, height: 38)
                                Image(systemName: tile.icon)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(tile.tint)
                            }
                            Text(tile.label)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(PawlyColors.ink)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: Radius.cardLg, style: .continuous)
                                .fill(tile.bg)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.screenHorizontal)
        }
    }
}

// MARK: - Upcoming This Week Section

struct UpcomingWeekSection: View {
    let pet: PetDTO
    let onTapReminder: (ReminderDTO) -> Void
    @EnvironmentObject var dataStore: DataStore

    private var items: [(instance: ReminderInstanceDTO, reminder: ReminderDTO)] {
        let now = Date()
        let weekEnd = Calendar.current.date(byAdding: .day, value: 7, to: Date().endOfDay) ?? now
        let tomorrowStart = Date().endOfDay
        let petReminderIds = Set(dataStore.reminders.filter { $0.petId == pet.id }.map(\.id))
        return dataStore.reminderInstances
            .filter { instance in
                guard let rid = instance.reminderId, petReminderIds.contains(rid) else { return false }
                return instance.statusRaw == "upcoming"
                    && instance.scheduledAt > tomorrowStart
                    && instance.scheduledAt <= weekEnd
            }
            .sorted { $0.scheduledAt < $1.scheduledAt }
            .prefix(5)
            .compactMap { instance -> (ReminderInstanceDTO, ReminderDTO)? in
                guard let reminder = dataStore.reminders.first(where: { $0.id == instance.reminderId }) else { return nil }
                return (instance, reminder)
            }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Upcoming this week")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(PawlyColors.ink)
                Spacer()
                if !items.isEmpty {
                    Text("\(items.count)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(PawlyColors.inkSoft)
                }
            }
            .padding(.horizontal, Spacing.screenHorizontal)

            if items.isEmpty {
                Text("No reminders in the next 7 days.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(PawlyColors.inkSoft)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 18)
                    .padding(.horizontal, 14)
                    .background(
                        RoundedRectangle(cornerRadius: Radius.cardLg, style: .continuous)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
                    )
                    .padding(.horizontal, Spacing.screenHorizontal)
            } else {
                VStack(spacing: 8) {
                    ForEach(items, id: \.instance.id) { item in
                        UpcomingRow(reminder: item.reminder, scheduledAt: item.instance.scheduledAt) {
                            onTapReminder(item.reminder)
                        }
                    }
                }
                .padding(.horizontal, Spacing.screenHorizontal)
            }
        }
    }
}

private struct UpcomingRow: View {
    let reminder: ReminderDTO
    let scheduledAt: Date
    let onTap: () -> Void

    private var dateText: String {
        let cal = Calendar.current
        let f = DateFormatter()
        if cal.isDateInTomorrow(scheduledAt) {
            f.dateFormat = "h:mm a"
            return "Tomorrow · \(f.string(from: scheduledAt))"
        }
        f.dateFormat = "EEE · h:mm a"
        return f.string(from: scheduledAt)
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(PawlyColors.peachAccent.opacity(0.15)).frame(width: 36, height: 36)
                    Image(systemName: ReminderType(rawValue: reminder.typeRaw)?.sfSymbol ?? "bell.fill")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(PawlyColors.peachAccent)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(reminder.title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(PawlyColors.ink)
                        .lineLimit(1)
                    Text(dateText)
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundStyle(PawlyColors.inkSoft)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(PawlyColors.inkSoft.opacity(0.6))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: Radius.cardLg, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Recent Activity Section

struct RecentActivitySection: View {
    let pet: PetDTO
    @EnvironmentObject var dataStore: DataStore

    private var recent: [LogEntryDTO] {
        dataStore.logEntries
            .filter { $0.petId == pet.id }
            .sorted { $0.at > $1.at }
            .prefix(5)
            .map { $0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent activity")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(PawlyColors.ink)
                .padding(.horizontal, Spacing.screenHorizontal)

            if recent.isEmpty {
                Text("Nothing logged yet. Use Quick log to record meals, walks, or weight.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(PawlyColors.inkSoft)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 18)
                    .padding(.horizontal, 14)
                    .background(
                        RoundedRectangle(cornerRadius: Radius.cardLg, style: .continuous)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
                    )
                    .padding(.horizontal, Spacing.screenHorizontal)
            } else {
                VStack(spacing: 8) {
                    ForEach(recent) { entry in
                        ActivityRow(entry: entry)
                    }
                }
                .padding(.horizontal, Spacing.screenHorizontal)
            }
        }
    }
}

private struct ActivityRow: View {
    let entry: LogEntryDTO

    private var kind: LogKind { LogKind(rawValue: entry.kindRaw) ?? .meal }

    private var timeText: String {
        let f = DateFormatter()
        if Calendar.current.isDateInToday(entry.at) {
            f.dateFormat = "h:mm a"
            return "Today · \(f.string(from: entry.at))"
        }
        if Calendar.current.isDateInYesterday(entry.at) {
            f.dateFormat = "h:mm a"
            return "Yesterday · \(f.string(from: entry.at))"
        }
        f.dateFormat = "MMM d · h:mm a"
        return f.string(from: entry.at)
    }

    private var displayDetail: String {
        if !entry.detail.isEmpty { return entry.detail }
        return kind.displayName
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(PawlyColors.peachAccentSoft).frame(width: 34, height: 34)
                Image(systemName: kind.sfSymbol)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(PawlyColors.peachAccent)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(displayDetail)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(PawlyColors.ink)
                    .lineLimit(1)
                Text(timeText)
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundStyle(PawlyColors.inkSoft)
            }
            Spacer()
            if let value = entry.numericValue {
                Text(kind == .weight ? "\(String(format: "%.1f", value)) kg" : "\(Int(value))")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(PawlyColors.inkSoft)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: Radius.cardLg, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
        )
    }
}

// MARK: - Pet Info Card

struct PetInfoCard: View {
    let pet: PetDTO

    private var ageText: String {
        guard let dob = pet.dateOfBirth else { return "—" }
        let comps = Calendar.current.dateComponents([.year, .month], from: dob, to: .now)
        let y = comps.year ?? 0
        let m = comps.month ?? 0
        if y == 0 { return "\(max(0, m)) mo" }
        if m == 0 { return "\(y) yr" }
        return "\(y) yr \(m) mo"
    }

    private var weightText: String {
        guard let kg = pet.weightKg else { return "—" }
        return "\(String(format: "%.1f", kg)) kg"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            HStack(spacing: 12) {
                PetAvatarDTO(pet: pet, size: 56)
                VStack(alignment: .leading, spacing: 2) {
                    Text(pet.name)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(PawlyColors.ink)
                    Text("\(Species(rawValue: pet.speciesRaw)?.displayName ?? pet.speciesRaw) · \(pet.breed.isEmpty ? "Mixed" : pet.breed)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(PawlyColors.inkSoft)
                        .lineLimit(1)
                }
                Spacer()
            }

            Divider().background(PawlyColors.inkSoft.opacity(0.15))

            HStack(spacing: 0) {
                infoColumn("Age", value: ageText)
                Divider().frame(height: 32).background(PawlyColors.inkSoft.opacity(0.15))
                infoColumn("Weight", value: weightText)
                Divider().frame(height: 32).background(PawlyColors.inkSoft.opacity(0.15))
                infoColumn("Vet", value: pet.vetName.isEmpty ? "Not set" : pet.vetName)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: Radius.cardLg, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
        )
    }

    private func infoColumn(_ label: String, value: String) -> some View {
        VStack(spacing: 3) {
            Text(label.uppercased())
                .font(.system(size: 9.5, weight: .bold))
                .foregroundStyle(PawlyColors.inkSoft)
                .tracking(0.5)
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(PawlyColors.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - PawMD Home Card

struct PawMDHomeCard: View {
    let petName: String

    var body: some View {
        NavigationLink(destination: AIDoctorView()) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(PawlyColors.navySoft)
                        .frame(width: 44, height: 44)
                    Image(systemName: "stethoscope")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(PawlyColors.navy)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("PawMD")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(PawlyColors.ink)
                        Text("Dr. Ruff")
                            .font(.system(size: 10, weight: .semibold))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(PawlyColors.navySoft))
                            .foregroundStyle(PawlyColors.navy)
                    }
                    Text("Ask about \(petName)'s health — get vet-quality guidance")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(PawlyColors.inkSoft)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(PawlyColors.inkSoft.opacity(0.4))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .fill(PawlyColors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .stroke(PawlyColors.navy.opacity(0.1), lineWidth: 0.75)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Previews

#Preview("Home") {
    NavigationStack { HomeView() }
        .environmentObject(PetContextStore())
        .environmentObject(DataStore.shared)
}
