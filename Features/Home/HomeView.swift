import SwiftUI

/// PRD §6.2 — Home tab. Top-to-bottom composition.
struct HomeView: View {
    @EnvironmentObject var petContext: PetContextStore
    @EnvironmentObject var dataStore: DataStore

    var activePet: PetDTO? {
        dataStore.pets.first(where: { $0.id == petContext.activePetID }) ?? dataStore.pets.first
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.m) {
                // Pet switcher + greeting row
                HStack(alignment: .center) {
                    PetSwitcherCarousel(pets: dataStore.pets)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 0) {
                        Text("Today").font(PawlyFont.caption).foregroundStyle(PawlyColors.slate)
                        Text(Date(), format: .dateTime.weekday(.wide).day().month(.abbreviated))
                            .font(PawlyFont.headingMedium)
                            .foregroundStyle(PawlyColors.ink)
                    }
                }

                if let pet = activePet {
                    PetHeaderCard(pet: pet)
                    TodaySummaryCard(pet: pet)
                    UpNextCard(pet: pet)
                    DailyCareCard(pet: pet)
                    DiscoverPromptCard(pet: pet)
                } else {
                    EmptyPetsState()
                }
            }
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.top, Spacing.m)
            .padding(.bottom, Spacing.xxl)
        }
        .background(PawlyColors.cream.ignoresSafeArea())
        .refreshable {
            await dataStore.fetchAllData()
        }
    }
}

// MARK: - Pet header

private struct PetHeaderCard: View {
    let pet: PetDTO

    var body: some View {
        PawlyCard {
            HStack(alignment: .center, spacing: Spacing.m) {
                PetAvatarDTO(pet: pet, size: 68)

                VStack(alignment: .leading, spacing: 2) {
                    Text(pet.name)
                        .font(PawlyFont.displayMedium)
                        .foregroundStyle(PawlyColors.ink)
                    Text("\(Species(rawValue: pet.speciesRaw)?.displayName ?? pet.speciesRaw) • \(ageDescription)")
                        .font(PawlyFont.bodyMedium)
                        .foregroundStyle(PawlyColors.slate)
                }
                Spacer()
                MoodSelectorDTO(pet: pet)
            }
        }
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

// MARK: - Mood selector

struct MoodSelectorDTO: View {
    @EnvironmentObject var dataStore: DataStore
    let pet: PetDTO
    @State private var showing = false

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

// MARK: - Today summary

private struct TodaySummaryCard: View {
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
        dataStore.reminderInstances
            .filter { instance in
                dataStore.reminders(forPetId: pet.id).contains(where: { $0.id == instance.reminderId }) &&
                instance.statusRaw == "completed" &&
                (instance.completedAt ?? .distantPast) >= startOfDay &&
                (instance.completedAt ?? .distantPast) <= endOfDay
            }
            .count
    }
    private var walksDone: Int {
        dataStore.logEntries(forPetId: pet.id)
            .filter { $0.kindRaw == "walk" && $0.at >= startOfDay && $0.at <= endOfDay }
            .count
    }

    var body: some View {
        PawlyCard {
            VStack(alignment: .leading, spacing: Spacing.s) {
                Text("Today").font(PawlyFont.caption).foregroundStyle(PawlyColors.slate)
                HStack(spacing: Spacing.m) {
                    Stat(value: mealsLogged, label: "meals", symbol: "fork.knife")
                    Divider().frame(height: 40).overlay(PawlyColors.sand)
                    Stat(value: medsGiven,   label: "meds",  symbol: "pills.fill")
                    Divider().frame(height: 40).overlay(PawlyColors.sand)
                    Stat(value: walksDone,   label: "walks", symbol: "figure.walk")
                }
            }
        }
    }

    private struct Stat: View {
        let value: Int
        let label: String
        let symbol: String
        var body: some View {
            HStack(spacing: Spacing.xs) {
                Image(systemName: symbol).foregroundStyle(PawlyColors.forest)
                VStack(alignment: .leading) {
                    Text("\(value)").font(PawlyFont.headingLarge).foregroundStyle(PawlyColors.ink)
                    Text(label).font(PawlyFont.captionSmall).foregroundStyle(PawlyColors.slate)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Up next reminders

private struct UpNextCard: View {
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
            .prefix(2)
            .map { $0 }
    }

    var body: some View {
        PawlyCard {
            VStack(alignment: .leading, spacing: Spacing.s) {
                HStack {
                    Text("Up next").font(PawlyFont.headingMedium).foregroundStyle(PawlyColors.ink)
                    Spacer()
                    NavigationLink(destination: RemindersListViewDTO(pet: pet)) {
                        Text("See all").font(PawlyFont.caption).foregroundStyle(PawlyColors.forest)
                    }
                }
                if upcoming.isEmpty {
                    Text("All caught up. Your pet approves. 🌿")
                        .font(PawlyFont.bodyMedium)
                        .foregroundStyle(PawlyColors.slate)
                        .padding(.vertical, Spacing.s)
                } else {
                    ForEach(upcoming) { inst in
                        UpNextRowDTO(instance: inst) {
                            markDone(inst)
                        }
                    }
                }
            }
        }
    }

    private func markDone(_ inst: ReminderInstanceDTO) {
        Haptics.success()
        Task {
            await dataStore.toggleReminderInstance(inst)
        }
    }
}

private struct UpNextRowDTO: View {
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
                    .foregroundStyle(PawlyColors.forest)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(PawlyColors.cream))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(reminder?.title ?? "Reminder")
                    .font(PawlyFont.bodyLarge).foregroundStyle(PawlyColors.ink)
                Text(instance.scheduledAt, format: .dateTime.hour().minute())
                    .font(PawlyFont.caption).foregroundStyle(PawlyColors.slate)
            }
            Spacer()
            Button(action: onMarkDone) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(PawlyColors.forest)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Mark done")
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Daily Care Checklist

private struct DailyTask: Identifiable {
    let id = UUID()
    let title: String
    let symbol: String
    let kind: LogKind
    let detail: String
}

private struct DailyCareCard: View {
    @EnvironmentObject var dataStore: DataStore
    let pet: PetDTO
    @State private var showDetailSheet = false
    @State private var selectedTask: DailyTask?

    private let tasks: [DailyTask] = [
        DailyTask(title: "Morning meal",  symbol: "sunrise.fill",      kind: .meal,       detail: "Morning meal"),
        DailyTask(title: "Evening meal",  symbol: "moon.fill",         kind: .meal,       detail: "Evening meal"),
        DailyTask(title: "Walk",          symbol: "figure.walk",       kind: .walk,       detail: ""),
        DailyTask(title: "Fresh water",   symbol: "drop.fill",         kind: .hygiene,    detail: "Fresh water"),
        DailyTask(title: "Medication",    symbol: "pills.fill",        kind: .medication, detail: ""),
        DailyTask(title: "Play time",     symbol: "tennisball.fill",   kind: .walk,       detail: "Play time"),
        DailyTask(title: "Bathroom check",symbol: "toilet.fill",       kind: .hygiene,    detail: "Bathroom check"),
        DailyTask(title: "Brush / Groom", symbol: "sparkles",          kind: .hygiene,    detail: "Brush / Groom"),
    ]

    private var startOfDay: Date { Date().startOfDay }
    private var endOfDay:   Date { Date().endOfDay }

    private func countToday(for kind: LogKind) -> Int {
        dataStore.logEntries(forPetId: pet.id)
            .filter { $0.kindRaw == kind.rawValue && $0.at >= startOfDay && $0.at <= endOfDay }
            .count
    }

    var body: some View {
        PawlyCard {
            VStack(alignment: .leading, spacing: Spacing.s) {
                HStack {
                    Text("Daily care")
                        .font(PawlyFont.headingMedium)
                        .foregroundStyle(PawlyColors.ink)
                    Spacer()
                    let doneCount = tasks.filter { countToday(for: $0.kind) > 0 }.count
                    Text("\(doneCount)/\(tasks.count)")
                        .font(PawlyFont.caption)
                        .foregroundStyle(PawlyColors.slate)
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.s) {
                    ForEach(tasks) { task in
                        TaskButton(
                            task: task,
                            count: countToday(for: task.kind)
                        ) {
                            logTask(task)
                        }
                    }
                }
            }
        }
    }

    private func logTask(_ task: DailyTask) {
        Haptics.success()
        Task {
            await dataStore.createLogEntry(
                forPetId: pet.id,
                kind: task.kind,
                detail: task.detail
            )
        }
    }
}

private struct TaskButton: View {
    let task: DailyTask
    let count: Int
    let action: () -> Void

    private var isDone: Bool { count > 0 }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.s) {
                ZStack {
                    Circle()
                        .fill(isDone ? PawlyColors.sage.opacity(0.15) : PawlyColors.cream)
                        .frame(width: 36, height: 36)
                    Image(systemName: task.symbol)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(isDone ? PawlyColors.sage : PawlyColors.forest)
                }

                VStack(alignment: .leading, spacing: 0) {
                    Text(task.title)
                        .font(PawlyFont.bodyMedium)
                        .foregroundStyle(isDone ? PawlyColors.slate : PawlyColors.ink)
                        .strikethrough(isDone)
                    if count > 0 {
                        Text("Done \(count)")
                            .font(PawlyFont.captionSmall)
                            .foregroundStyle(PawlyColors.sage)
                    }
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(isDone ? PawlyColors.sage : PawlyColors.sand, lineWidth: 1.5)
                        .frame(width: 22, height: 22)
                    if isDone {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(PawlyColors.sage)
                    }
                }
            }
            .padding(.horizontal, Spacing.s)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: Radius.input, style: .continuous)
                    .fill(isDone ? PawlyColors.surface.opacity(0.5) : PawlyColors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.input, style: .continuous)
                    .stroke(isDone ? PawlyColors.sage.opacity(0.3) : PawlyColors.sand.opacity(0.6), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Discover prompt (contextual)

private struct DiscoverPromptCard: View {
    @EnvironmentObject var dataStore: DataStore
    let pet: PetDTO

    private var message: String? {
        // PRD example: "It has been 27 days since deworming".
        let dewormingReminder = dataStore.reminders(forPetId: pet.id)
            .first { $0.typeRaw == "dewormingTickFlea" }
        
        if let reminder = dewormingReminder {
            let completedInstance = dataStore.reminderInstances(forReminderId: reminder.id)
                .filter { $0.statusRaw == "completed" }
                .max { ($0.completedAt ?? .distantPast) < ($1.completedAt ?? .distantPast) }
            
            if let when = completedInstance?.completedAt {
                let days = Date().daysFrom(when)
                if days >= 20 {
                    return "It has been \(days) days since deworming. A gentle reminder — most products cover 30."
                }
            }
        }
        return nil
    }

    var body: some View {
        if let message {
            PawlyCard {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "sparkles").foregroundStyle(PawlyColors.peach)
                        Text("A little nudge").font(PawlyFont.caption).foregroundStyle(PawlyColors.slate)
                    }
                    Text(message)
                        .font(PawlyFont.bodyLarge)
                        .foregroundStyle(PawlyColors.ink)
                }
            }
        } else {
            EmptyView()
        }
    }
}

// MARK: - Empty pets state

private struct EmptyPetsState: View {
    var body: some View {
        PawlyCard {
            VStack(spacing: Spacing.s) {
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(PawlyColors.forest)
                Text("No pets yet")
                    .font(PawlyFont.headingMedium)
                    .foregroundStyle(PawlyColors.ink)
                Text("Add your first pet to get started.")
                    .font(PawlyFont.bodyMedium)
                    .foregroundStyle(PawlyColors.slate)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.m)
        }
    }
}

#Preview("Home") {
    HomeView()
        .environmentObject(PetContextStore())
        .environmentObject(DataStore.shared)
}
