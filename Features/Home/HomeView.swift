import SwiftUI

/// Home tab — top-to-bottom composition with clear visual hierarchy.
/// Hero pet section → today's care → up next → discover nudge.
struct HomeView: View {
    @EnvironmentObject var petContext: PetContextStore
    @EnvironmentObject var dataStore: DataStore

    var activePet: PetDTO? {
        dataStore.pets.first(where: { $0.id == petContext.activePetID }) ?? dataStore.pets.first
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // ── Header row ──────────────────────────────────
                HStack(alignment: .center) {
                    PetSwitcherCarousel(pets: dataStore.pets)
                    Spacer()
                    dateBlock
                }
                .padding(.horizontal, Spacing.screenHorizontal)
                .padding(.top, Spacing.m)
                .padding(.bottom, Spacing.l)

                if let pet = activePet {
                    // ── Pet hero card ──────────────────────────
                    PetHeroCard(pet: pet)
                        .padding(.horizontal, Spacing.screenHorizontal)
                        .padding(.bottom, Spacing.l)

                    // ── Today's care ──────────────────────────
                    TodayCareSection(pet: pet)
                        .padding(.horizontal, Spacing.screenHorizontal)
                        .padding(.bottom, Spacing.l)

                    // ── Up next ────────────────────────────────
                    UpNextSection(pet: pet)
                        .padding(.horizontal, Spacing.screenHorizontal)
                        .padding(.bottom, Spacing.l)

                    // ── Discover nudge ────────────────────────
                    DiscoverNudgeCard(pet: pet)
                        .padding(.horizontal, Spacing.screenHorizontal)
                        .padding(.bottom, Spacing.xxl)

                } else {
                    EmptyPetsState()
                        .padding(.horizontal, Spacing.screenHorizontal)
                        .padding(.top, Spacing.xxl)
                }
            }
        }
        .background(PawlyColors.cream.ignoresSafeArea())
        .refreshable {
            await dataStore.fetchAllData()
        }
    }

    private var dateBlock: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text("Today")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(PawlyColors.slate)
            Text(Date(), format: .dateTime.day().month(.abbreviated))
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(PawlyColors.ink)
        }
    }
}

// MARK: - Pet Hero Card

private struct PetHeroCard: View {
    @EnvironmentObject var dataStore: DataStore
    let pet: PetDTO

    private var startOfDay: Date { Date().startOfDay }
    private var endOfDay:   Date { Date().endOfDay }

    private var mealsLogged: Int {
        dataStore.logEntries(forPetId: pet.id)
            .filter { $0.kindRaw == "meal" && $0.at >= startOfDay && $0.at <= endOfDay }
            .count
    }
    private var medsGiven: Int {
        dataStore.logEntries(forPetId: pet.id)
            .filter { $0.kindRaw == "medication" && $0.at >= startOfDay && $0.at <= endOfDay }
            .count
    }
    private var walksDone: Int {
        dataStore.logEntries(forPetId: pet.id)
            .filter { $0.kindRaw == "walk" && $0.at >= startOfDay && $0.at <= endOfDay }
            .count
    }

    var body: some View {
        HStack(spacing: Spacing.m) {
            // Avatar
            PetAvatarDTO(pet: pet, size: 72)

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(pet.name)
                    .font(PawlyFont.displayMedium)
                    .foregroundStyle(PawlyColors.ink)

                Text("\(Species(rawValue: pet.speciesRaw)?.displayName ?? pet.speciesRaw) · \(ageDescription)")
                    .font(PawlyFont.bodyMedium)
                    .foregroundStyle(PawlyColors.slate)

                // Quick stats row
                HStack(spacing: Spacing.m) {
                    quickStat(mealsLogged, symbol: "fork.knife", label: "meals")
                    quickStatDivider
                    quickStat(walksDone, symbol: "figure.walk", label: "walks")
                    quickStatDivider
                    quickStat(medsGiven, symbol: "pills.fill", label: "meds")
                }
                .padding(.top, 6)
            }

            Spacer()

            // Mood picker
            MoodSelectorDTO(pet: pet)
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
        .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 4)
    }

    private func quickStat(_ value: Int, symbol: String, label: String) -> some View {
        VStack(spacing: 2) {
            Image(systemName: symbol)
                .font(.system(size: 12))
                .foregroundStyle(PawlyColors.forest)
            Text("\(value)")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(PawlyColors.ink)
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(PawlyColors.slate)
        }
    }

    private var quickStatDivider: some View {
        Rectangle()
            .fill(PawlyColors.sand.opacity(0.5))
            .frame(width: 0.75, height: 28)
    }

    private var ageDescription: String {
        guard let dob = pet.dateOfBirth else { return "Unknown age" }
        let comps = Calendar.current.dateComponents([.year, .month], from: dob, to: .now)
        let y = comps.year ?? 0
        let m = comps.month ?? 0
        if y == 0 { return "\(max(0, m))mo" }
        if m == 0 { return "\(y)y" }
        return "\(y)y \(m)mo"
    }
}

// MARK: - Today Care Section

private struct TodayCareSection: View {
    @EnvironmentObject var dataStore: DataStore
    let pet: PetDTO

    private let tasks: [CareTask] = [
        CareTask(title: "Morning meal",  symbol: "sunrise.fill",      kind: .meal,       detail: "Morning meal"),
        CareTask(title: "Evening meal",  symbol: "moon.fill",         kind: .meal,       detail: "Evening meal"),
        CareTask(title: "Walk",          symbol: "figure.walk",        kind: .walk,       detail: ""),
        CareTask(title: "Fresh water",   symbol: "drop.fill",         kind: .hygiene,    detail: "Fresh water"),
        CareTask(title: "Medication",    symbol: "pills.fill",        kind: .medication, detail: ""),
        CareTask(title: "Play time",     symbol: "tennisball.fill",   kind: .walk,       detail: "Play time"),
        CareTask(title: "Brush / Groom", symbol: "sparkles",          kind: .hygiene,    detail: "Brush / Groom"),
        CareTask(title: "Bathroom",      symbol: "toilet.fill",       kind: .hygiene,    detail: "Bathroom check"),
    ]

    private var startOfDay: Date { Date().startOfDay }
    private var endOfDay:   Date { Date().endOfDay }

    private func countToday(for kind: LogKind) -> Int {
        dataStore.logEntries(forPetId: pet.id)
            .filter { $0.kindRaw == kind.rawValue && $0.at >= startOfDay && $0.at <= endOfDay }
            .count
    }

    private var doneCount: Int {
        tasks.filter { countToday(for: $0.kind) > 0 }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            // Section header
            HStack {
                Text("Today's care")
                    .font(PawlyFont.headingMedium)
                    .foregroundStyle(PawlyColors.ink)
                Spacer()
                Text("\(doneCount)/\(tasks.count) done")
                    .font(PawlyFont.caption)
                    .foregroundStyle(doneCount == tasks.count ? PawlyColors.sage : PawlyColors.slate)
            }

            // Task grid — 2 columns
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(tasks) { task in
                    CareTaskButton(task: task, count: countToday(for: task.kind)) {
                        logTask(task)
                    }
                }
            }
        }
    }

    private func logTask(_ task: CareTask) {
        Haptics.success()
        Task {
            await dataStore.createLogEntry(forPetId: pet.id, kind: task.kind, detail: task.detail)
        }
    }
}

private struct CareTask: Identifiable {
    let id = UUID()
    let title: String
    let symbol: String
    let kind: LogKind
    let detail: String
}

private struct CareTaskButton: View {
    let task: CareTask
    let count: Int
    let action: () -> Void

    private var isDone: Bool { count > 0 }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(isDone ? PawlyColors.forestLight : PawlyColors.surface)
                        .frame(width: 34, height: 34)
                    Image(systemName: task.symbol)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(isDone ? PawlyColors.forest : PawlyColors.slate)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(task.title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(isDone ? PawlyColors.slate : PawlyColors.ink)
                        .strikethrough(isDone, color: PawlyColors.slate)
                    if isDone {
                        Text("Done \(count)x")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(PawlyColors.sage)
                    }
                }

                Spacer()

                Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundStyle(isDone ? PawlyColors.forest : PawlyColors.sand)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: Radius.small, style: .continuous)
                    .fill(isDone ? PawlyColors.forestLight : PawlyColors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.small, style: .continuous)
                    .stroke(isDone ? PawlyColors.forest.opacity(0.2) : PawlyColors.sand.opacity(0.5), lineWidth: 0.75)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Up Next Section

private struct UpNextSection: View {
    @EnvironmentObject var dataStore: DataStore
    let pet: PetDTO

    private var upcoming: [ReminderInstanceDTO] {
        let now = Date()
        let petReminderIds = dataStore.reminders(forPetId: pet.id).map { $0.id }
        return dataStore.reminderInstances
            .filter { instance in
                petReminderIds.contains(instance.reminderId ?? UUID()) &&
                instance.statusRaw == "upcoming" &&
                instance.scheduledAt >= now.addingTimeInterval(-600)
            }
            .sorted { $0.scheduledAt < $1.scheduledAt }
            .prefix(3)
            .map { $0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            HStack {
                Text("Up next")
                    .font(PawlyFont.headingMedium)
                    .foregroundStyle(PawlyColors.ink)
                Spacer()
                NavigationLink(destination: RemindersListViewDTO(pet: pet)) {
                    Text("See all")
                        .font(PawlyFont.caption)
                        .foregroundStyle(PawlyColors.forest)
                }
            }

            if upcoming.isEmpty {
                HStack(spacing: Spacing.s) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(PawlyColors.sage)
                    Text("All caught up — your pet approves.")
                        .font(PawlyFont.bodyMedium)
                        .foregroundStyle(PawlyColors.slate)
                }
                .padding(.vertical, Spacing.s)
            } else {
                ForEach(upcoming) { inst in
                    UpNextRow(instance: inst) { markDone(inst) }
                }
            }
        }
    }

    private func markDone(_ inst: ReminderInstanceDTO) {
        Haptics.success()
        Task { await dataStore.toggleReminderInstance(inst) }
    }
}

private struct UpNextRow: View {
    @EnvironmentObject var dataStore: DataStore
    let instance: ReminderInstanceDTO
    var onMarkDone: () -> Void

    private var reminder: ReminderDTO? {
        dataStore.reminders.first { $0.id == instance.reminderId }
    }

    var body: some View {
        HStack(spacing: Spacing.m) {
            if let reminder = reminder,
               let type = ReminderType(rawValue: reminder.typeRaw) {
                Image(systemName: type.sfSymbol)
                    .font(.system(size: 16))
                    .foregroundStyle(PawlyColors.forest)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(PawlyColors.forestLight))
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(reminder?.title ?? "Reminder")
                    .font(PawlyFont.bodyLarge)
                    .foregroundStyle(PawlyColors.ink)
                Text(instance.scheduledAt, format: .dateTime.hour().minute())
                    .font(PawlyFont.caption)
                    .foregroundStyle(PawlyColors.slate)
            }
            Spacer()
            Button(action: onMarkDone) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(PawlyColors.forest)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Mark done")
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
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

// MARK: - Discover Nudge

private struct DiscoverNudgeCard: View {
    @EnvironmentObject var dataStore: DataStore
    let pet: PetDTO

    private var message: String? {
        let dewormingReminder = dataStore.reminders(forPetId: pet.id)
            .first { $0.typeRaw == "dewormingTickFlea" }

        if let reminder = dewormingReminder {
            let completedInstance = dataStore.reminderInstances(forReminderId: reminder.id)
                .filter { $0.statusRaw == "completed" }
                .max { ($0.completedAt ?? .distantPast) < ($1.completedAt ?? .distantPast) }

            if let when = completedInstance?.completedAt {
                let days = Date().daysFrom(when)
                if days >= 20 {
                    return "It has been \(days) days since deworming. Most products cover 30 days."
                }
            }
        }
        return nil
    }

    var body: some View {
        if let message {
            HStack(spacing: Spacing.s) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(PawlyColors.peach)
                Text(message)
                    .font(PawlyFont.bodyMedium)
                    .foregroundStyle(PawlyColors.ink)
                Spacer()
            }
            .padding(Spacing.m)
            .background(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .fill(PawlyColors.peachLight)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .stroke(PawlyColors.peach.opacity(0.3), lineWidth: 0.75)
            )
        } else {
            EmptyView()
        }
    }
}

// MARK: - Empty State

private struct EmptyPetsState: View {
    var body: some View {
        VStack(spacing: Spacing.m) {
            ZStack {
                Circle().fill(PawlyColors.forestLight).frame(width: 80, height: 80)
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(PawlyColors.forest)
            }
            VStack(spacing: 6) {
                Text("No pets yet")
                    .font(PawlyFont.headingMedium)
                    .foregroundStyle(PawlyColors.ink)
                Text("Add your first pet to get started.")
                    .font(PawlyFont.bodyMedium)
                    .foregroundStyle(PawlyColors.slate)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxl)
    }
}

#Preview("Home") {
    HomeView()
        .environmentObject(PetContextStore())
        .environmentObject(DataStore.shared)
}

// MARK: - Pet Avatar DTO

struct PetAvatarDTO: View {
    let pet: PetDTO
    var size: CGFloat = 56

    var body: some View {
        ZStack {
            if let photoURL = pet.photoURL,
               let url = URL(string: photoURL) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Color(hex: pet.accentHex)
                }
            } else {
                Color(hex: pet.accentHex)
                    .overlay(
                        Image(systemName: Species(rawValue: pet.speciesRaw)?.sfSymbol ?? "pawprint.fill")
                            .foregroundStyle(Color.white.opacity(0.9))
                            .font(.system(size: size * 0.4, weight: .semibold))
                    )
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .stroke(Color(hex: pet.accentHex), lineWidth: 2)
        )
    }
}

// MARK: - Mood Selector DTO

struct MoodSelectorDTO: View {
    @EnvironmentObject var dataStore: DataStore
    let pet: PetDTO

    private var latest: MoodType? {
        guard let moodRaw = dataStore.moodEntries(forPetId: pet.id).first?.moodRaw else { return nil }
        return MoodType(rawValue: moodRaw)
    }

    var body: some View {
        Menu {
            ForEach(MoodType.allCases) { m in
                Button {
                    Haptics.light()
                    Task {
                        await dataStore.createMoodEntry(forPetId: pet.id, mood: m)
                    }
                } label: {
                    Label("\(m.emoji)  \(m.displayName)", systemImage: "")
                }
            }
        } label: {
            Text(latest?.emoji ?? "🙂")
                .font(.system(size: 30))
                .frame(width: 44, height: 44)
                .background(Circle().fill(PawlyColors.cream))
                .overlay(Circle().stroke(PawlyColors.sand, lineWidth: 1))
        }
        .accessibilityLabel("Mood picker")
    }
}