import SwiftUI

// MARK: - Home View

struct HomeView: View {
    @EnvironmentObject var petContext: PetContextStore
    @EnvironmentObject var dataStore: DataStore

    var activePet: PetDTO? {
        dataStore.pets.first { $0.id == petContext.activePetID } ?? dataStore.pets.first
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                headerSection
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .padding(.top, Spacing.m)
                    .padding(.bottom, Spacing.l)

                if let pet = activePet {
                    // Pet selector
                    PetSelectorRow(pets: dataStore.pets, selectedId: petContext.activePetID) { newId in
                        petContext.setActive(dataStore.pets.first { $0.id == newId }!)
                    } onAdd: {}
                    .padding(.horizontal, Spacing.screenHorizontal)

                    // Streak bar
                    HomeStreakBar(pet: pet)
                        .padding(.horizontal, Spacing.screenHorizontal)
                        .padding(.top, Spacing.m)

                    // Wellness hero card
                    WellnessHeroCard(pet: pet)
                        .padding(.horizontal, Spacing.screenHorizontal)
                        .padding(.top, Spacing.m)

                    // Today's checklist
                    TodayChecklistSection(pet: pet)
                        .padding(.top, Spacing.xl)

                    // AI Tip card
                    AITipCard(tip: aiTips(for: pet), tag: aiTipTag(for: pet))
                        .padding(.horizontal, Spacing.screenHorizontal)
                        .padding(.top, Spacing.xl)

                    // Memories carousel
                    MemoriesCarousel(pet: pet)
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
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .top, spacing: 0) {
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
            Spacer()
            notificationButton
        }
    }

    private var notificationButton: some View {
        Button {
            // Notifications
        } label: {
            ZStack(alignment: .topTrailing) {
                Circle()
                    .fill(Color.white)
                    .frame(width: 38, height: 38)
                    .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
                Image(systemName: "bell")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(PawlyColors.ink)
                Circle()
                    .fill(PawlyColors.peachAccent)
                    .frame(width: 8, height: 8)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 1.5)
                            .frame(width: 8, height: 8)
                    )
                    .offset(x: 2, y: -2)
            }
        }
        .buttonStyle(.plain)
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

    private func aiTips(for pet: PetDTO) -> String {
        switch pet.speciesRaw.lowercased() {
        case "cat", "persian", "maine coon":
            return "Cats sleep 12–16 hrs daily — quiet napping is a healthy sign, not laziness."
        case "dog":
            return "Daily walks of 30+ minutes help maintain hip health and reduce anxiety."
        default:
            return "Fresh water daily is essential for all pets. Change water bowls every day."
        }
    }

    private func aiTipTag(for pet: PetDTO) -> String {
        switch pet.speciesRaw.lowercased() {
        case "cat", "persian", "maine coon": return "Wellness"
        case "dog": return "Activity"
        default: return "Care"
        }
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

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 14) {
                // Wellness ring
                WellnessRing(wellness: pet.wellnessPercent, size: 146, strokeWidth: 11)

                // Details
                VStack(alignment: .leading, spacing: 0) {
                    Text("\(pet.name) feels")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(PawlyColors.inkSoft)
                        .tracking(0.8)
                        .textCase(.uppercase)

                    Text("\(pet.mood) \(pet.moodEmoji)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(PawlyColors.ink)
                        .tracking(-0.01)
                        .padding(.top, 2)

                    Spacer()

                    VStack(spacing: 6) {
                        wellnessRow("Nutrition", value: 92, color: PawlyColors.wellnessNutrition)
                        wellnessRow("Activity",  value: 78, color: PawlyColors.wellnessActivity)
                        wellnessRow("Hydration", value: 85, color: PawlyColors.wellnessHydration)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
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

    private func wellnessRow(_ label: String, value: Int, color: Color) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
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

// MARK: - Today's Checklist

struct TodayChecklistSection: View {
    let pet: PetDTO
    @EnvironmentObject var dataStore: DataStore

    private var todayInstances: [ReminderInstanceDTO] {
        guard let petId = pet.id as UUID? else { return [] }
        return dataStore.reminderInstancesToday(forPetId: petId)
    }

    private var checklist: [ChecklistItem] {
        todayInstances.map { instance in
            let reminder = dataStore.reminders.first { $0.id == instance.reminderId }
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "h:mm a"
            return ChecklistItem(
                id: instance.id.uuidString,
                label: reminder?.title ?? instance.reminderId?.uuidString ?? "Task",
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
        .onAppear { }
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
            Text("Add reminders from the Track tab")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(PawlyColors.inkSoft.opacity(0.6))
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

// MARK: - Memories Carousel

struct MemoriesCarousel: View {
    let pet: PetDTO

    private let memories: [(date: String, caption: String, tone: Int)] = [
        ("Today", "Morning nap ☀️", 0),
        ("Yesterday", "New toy arrived!", 2),
        ("2 days", "Vet check — all good", 3),
        ("4 days", "Played with the neighbor cat", 5),
        ("1 week", "First time at the park", 4),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Recent memories")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(PawlyColors.ink)
                Spacer()
                Button { } label: {
                    HStack(spacing: 3) {
                        Text("See all")
                            .font(.system(size: 12.5, weight: .medium))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(PawlyColors.inkSoft)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Spacing.screenHorizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Array(memories.enumerated()), id: \.offset) { _, memory in
                        VStack(alignment: .leading, spacing: 6) {
                            PhotoMemoryTile(
                                tone: memory.tone,
                                emoji: Species(rawValue: pet.speciesRaw)?.emoji ?? "��",
                                badge: memory.date
                            )
                            Text(memory.caption)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(PawlyColors.ink)
                                .lineLimit(2)
                        }
                        .frame(width: 130)
                    }

                    // Add memory button
                    Button { } label: {
                        VStack(spacing: 6) {
                            Image(systemName: "camera")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundStyle(PawlyColors.inkSoft)
                            Text("Add memory")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(PawlyColors.inkSoft)
                        }
                        .frame(width: 130, height: 130)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [5, 3]))
                                .foregroundStyle(Color.black.opacity(0.15))
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, Spacing.screenHorizontal)
            }
        }
    }
}

// MARK: - Previews

#Preview("Home") {
    NavigationStack { HomeView() }
        .environmentObject(PetContextStore())
        .environmentObject(DataStore.shared)
}
