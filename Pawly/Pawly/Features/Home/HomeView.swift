import SwiftUI
import SwiftData

/// PRD §6.2 — Home tab. Top-to-bottom composition.
struct HomeView: View {
    @Query(
        filter: #Predicate<Pet> { $0.statusRaw == "active" },
        sort: [SortDescriptor(\Pet.createdAt)]
    ) private var pets: [Pet]

    @EnvironmentObject var petContext: PetContextStore

    var activePet: Pet? {
        pets.first(where: { $0.id == petContext.activePetID }) ?? pets.first
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.m) {
                // Pet switcher + greeting row
                HStack(alignment: .center) {
                    PetSwitcherCarousel(pets: pets)
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
                    ActivityFeedCard(pet: pet)
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
    }
}

// MARK: - Pet header

private struct PetHeaderCard: View {
    @Environment(\.modelContext) private var modelContext
    let pet: Pet

    var body: some View {
        PawlyCard {
            HStack(alignment: .center, spacing: Spacing.m) {
                PetAvatar(pet: pet, size: 68)

                VStack(alignment: .leading, spacing: 2) {
                    Text(pet.name)
                        .font(PawlyFont.displayMedium)
                        .foregroundStyle(PawlyColors.ink)
                    Text("\(pet.species.displayName) • \(pet.ageDescription)")
                        .font(PawlyFont.bodyMedium)
                        .foregroundStyle(PawlyColors.slate)
                }
                Spacer()
                MoodSelector(pet: pet)
            }
        }
    }
}

struct PetAvatar: View {
    let pet: Pet
    var size: CGFloat = 56

    var body: some View {
        ZStack {
            if let data = pet.photoData, let ui = UIImage(data: data) {
                Image(uiImage: ui).resizable().scaledToFill()
            } else {
                Color(hex: pet.accentHex)
                    .overlay(
                        Image(systemName: pet.species.sfSymbol)
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

struct MoodSelector: View {
    @Environment(\.modelContext) private var modelContext
    let pet: Pet
    @State private var showing = false

    private var latest: Mood? {
        pet.moodEntries.max(by: { $0.at < $1.at })?.mood
    }

    var body: some View {
        Menu {
            ForEach(Mood.allCases) { m in
                Button {
                    Haptics.light()
                    modelContext.insert(MoodEntry(pet: pet, mood: m))
                    try? modelContext.save()
                } label: {
                    Label("\(m.emoji)  \(m.label)", systemImage: "")
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
    let pet: Pet

    private var startOfDay: Date { Date().startOfDay }
    private var endOfDay:   Date { Date().endOfDay }

    private var mealsLogged: Int {
        pet.logEntries.filter { $0.kind == .meal && $0.at >= startOfDay && $0.at <= endOfDay }.count
    }
    private var medsGiven: Int {
        pet.reminders.flatMap(\.instances).filter {
            $0.status == .completed && ($0.completedAt ?? .distantPast) >= startOfDay
                && ($0.completedAt ?? .distantPast) <= endOfDay
        }.count
    }
    private var walksDone: Int {
        pet.logEntries.filter { $0.kind == .walk && $0.at >= startOfDay && $0.at <= endOfDay }.count
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
    @Environment(\.modelContext) private var modelContext
    let pet: Pet

    private var upcoming: [ReminderInstance] {
        let now = Date()
        let all = pet.reminders.flatMap(\.instances)
        return all
            .filter { $0.status == .upcoming && $0.scheduledAt >= now.addingTimeInterval(-600) }
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
                    NavigationLink(destination: RemindersListView(pet: pet)) {
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
                        UpNextRow(instance: inst) {
                            markDone(inst)
                        }
                    }
                }
            }
        }
    }

    private func markDone(_ inst: ReminderInstance) {
        Haptics.success()
        inst.status = .completed
        inst.completedAt = .now
        try? modelContext.save()
    }
}

private struct UpNextRow: View {
    let instance: ReminderInstance
    var onMarkDone: () -> Void

    var body: some View {
        HStack(spacing: Spacing.m) {
            if let type = instance.reminder?.type {
                Image(systemName: type.sfSymbol)
                    .foregroundStyle(PawlyColors.forest)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(PawlyColors.cream))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(instance.reminder?.title ?? "Reminder")
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

// MARK: - Activity feed

private struct ActivityFeedCard: View {
    let pet: Pet

    private var items: [ActivityItem] {
        let logs = pet.logEntries.map { ActivityItem.log($0) }
        let doneInstances = pet.reminders.flatMap(\.instances)
            .filter { $0.status == .completed && $0.completedAt != nil }
            .map { ActivityItem.instance($0) }
        return (logs + doneInstances)
            .sorted { $0.date > $1.date }
            .prefix(4)
            .map { $0 }
    }

    var body: some View {
        PawlyCard {
            VStack(alignment: .leading, spacing: Spacing.s) {
                Text("Last 24 hours").font(PawlyFont.headingMedium).foregroundStyle(PawlyColors.ink)
                if items.isEmpty {
                    Text("Nothing logged yet today.")
                        .font(PawlyFont.bodyMedium)
                        .foregroundStyle(PawlyColors.slate)
                } else {
                    ForEach(items) { item in
                        HStack(spacing: Spacing.s) {
                            Image(systemName: item.symbol)
                                .foregroundStyle(PawlyColors.sage)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 0) {
                                Text(item.title)
                                    .font(PawlyFont.bodyMedium)
                                    .foregroundStyle(PawlyColors.ink)
                                Text(item.date, style: .relative)
                                    .font(PawlyFont.captionSmall)
                                    .foregroundStyle(PawlyColors.slate)
                            }
                            Spacer()
                        }
                    }
                }
            }
        }
    }

    enum ActivityItem: Identifiable {
        case log(LogEntry)
        case instance(ReminderInstance)

        var id: UUID {
            switch self {
            case .log(let l): return l.id
            case .instance(let i): return i.id
            }
        }
        var date: Date {
            switch self {
            case .log(let l): return l.at
            case .instance(let i): return i.completedAt ?? i.scheduledAt
            }
        }
        var symbol: String {
            switch self {
            case .log(let l): return l.kind.sfSymbol
            case .instance(let i): return i.reminder?.type.sfSymbol ?? "checkmark"
            }
        }
        var title: String {
            switch self {
            case .log(let l):
                return "\(l.kind.displayName): \(l.detail.isEmpty ? "logged" : l.detail)"
            case .instance(let i):
                return "\(i.reminder?.title ?? "Reminder") — done"
            }
        }
    }
}

// MARK: - Discover prompt (contextual)

private struct DiscoverPromptCard: View {
    let pet: Pet

    private var message: String? {
        // PRD example: "It has been 27 days since deworming".
        if let last = pet.reminders
            .first(where: { $0.type == .dewormingTickFlea })?
            .instances
            .filter({ $0.status == .completed })
            .max(by: { ($0.completedAt ?? .distantPast) < ($1.completedAt ?? .distantPast) }),
           let when = last.completedAt {
            let days = Date().daysFrom(when)
            if days >= 20 {
                return "It has been \(days) days since deworming. A gentle reminder — most products cover 30."
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
        .environmentObject(PreviewSupport.previewPetContext)
        .modelContainer(PreviewSupport.container)
}
