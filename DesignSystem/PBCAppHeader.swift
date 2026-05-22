import SwiftUI

// MARK: - Sticky App Header
//
// Apple-quality sticky header with frosted glass background.
// Shows pet switcher on left, active pet context in center,
// and settings/notification actions on the right.
//

struct PBCAppHeader: View {
    @EnvironmentObject var petContext: PetContextStore
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var authService: AuthService

    @State private var showingAddPet = false
    @State private var showingSettings = false
    @State private var showingPetSwitcher = false
    @State private var showingNotifications = false
    @State private var taglineIndex = 0

    private var pets: [PetDTO] { dataStore.pets }

    private var activePet: PetDTO? {
        pets.first { $0.id == petContext.activePetID } ?? pets.first
    }

    var body: some View {
        VStack(spacing: 0) {
            // Main header bar
            HStack(spacing: 0) {
                // Left: Pet switcher / logo
                petSwitcherButton
                    .frame(minWidth: 120, alignment: .leading)

                // Center: App logo
                appLogo
                    .frame(maxWidth: .infinity)

                // Right: Actions
                HStack(spacing: 8) {
                    notificationButton
                    settingsButton
                }
                .frame(minWidth: 100, alignment: .trailing)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(headerBackground)

            // Sub-header: quick status bar (streak + wellness)
            if activePet != nil {
                statusBar
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsSheet()
        }
        .sheet(isPresented: $showingNotifications) {
            NotificationsSheet()
        }
        .sheet(isPresented: $showingPetSwitcher) {
            PetSwitcherSheet(pets: pets)
        }
        .sheet(isPresented: $showingAddPet) {
            PBCAddPetSheet(onDismiss: { showingAddPet = false })
        }
    }

    // MARK: - Components

    private var petSwitcherButton: some View {
        Button {
            Haptics.light()
            showingPetSwitcher = true
        } label: {
            HStack(spacing: 8) {
                petStack
            }
        }
        .buttonStyle(.plain)
    }

    private var petStack: some View {
        HStack(spacing: -8) {
            if pets.count > 1 {
                if let secondPet = pets.dropFirst().first {
                    headerAvatar(for: secondPet, size: 30, opacity: 0.7)
                }
                headerAvatar(for: activePet, size: 36, opacity: 1.0)
                    .zIndex(1)
            } else {
                headerAvatar(for: activePet, size: 34, opacity: 1.0)
            }
        }
        .overlay(
            Group {
                if pets.count > 1 {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(PawlyColors.inkSoft)
                        .offset(x: 22, y: 6)
                }
            }
        )
    }

    private var appLogo: some View {
        Image("AppLogo")
            .resizable()
            .scaledToFit()
            .frame(height: 34)
    }

    @ViewBuilder
    private func headerAvatar(for pet: PetDTO?, size: CGFloat, opacity: Double) -> some View {
        ZStack {
            if let photoURL = pet?.photoURL,
               let url = URL(string: photoURL) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    avatarPlaceholder(for: pet, size: size)
                }
            } else {
                avatarPlaceholder(for: pet, size: size)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.3, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: size * 0.3, style: .continuous)
                .stroke(Color.white, lineWidth: 1.5)
        )
        .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
        .opacity(opacity)
    }

    @ViewBuilder
    private func avatarPlaceholder(for pet: PetDTO?, size: CGFloat) -> some View {
        let accent = Color(hex: pet?.accentHex ?? "#1E3A5F")
        ZStack {
            accent
            if let pet, let species = Species(rawValue: pet.speciesRaw) {
                Image(systemName: species.sfSymbol)
                    .font(.system(size: size * 0.4, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
    }

    private var notificationButton: some View {
        Button {
            Haptics.light()
            showingNotifications = true
        } label: {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.6))
                    .frame(width: 36, height: 36)
                Image(systemName: "bell")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(PawlyColors.ink)
                    .symbolRenderingMode(.hierarchical)
            }
        }
        .buttonStyle(.plain)
    }

    private var settingsButton: some View {
        Button {
            Haptics.light()
            showingSettings = true
        } label: {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.6))
                    .frame(width: 36, height: 36)
                Image(systemName: "gearshape")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(PawlyColors.ink)
                    .symbolRenderingMode(.hierarchical)
            }
        }
        .buttonStyle(.plain)
    }

    private let taglines: [(String, String)] = [
        ("🐶", "Dogs can smell your emotions — literally"),
        ("🐱", "Cats only meow to talk to humans, not each other"),
        ("🐾", "A dog's nose print is as unique as a fingerprint"),
        ("😴", "Cats sleep 12–16 hours a day. Goals."),
        ("💓", "Dogs' hearts beat 60–140 times per minute"),
        ("🐠", "Goldfish have a memory span of up to 3 months"),
        ("🐕", "A wagging tail doesn't always mean happy — direction matters"),
        ("🦜", "Parrots can recognize themselves in a mirror"),
        ("🐱", "Cats have 32 muscles in each ear"),
        ("🐾", "Dogs dream just like humans do"),
        ("🌡️", "A healthy dog's temp runs 38–39°C — warmer than yours"),
        ("🐰", "Rabbits can't vomit — so diet really matters"),
        ("😸", "A cat's purr vibrates at 25–150 Hz — known to heal bones"),
        ("🐶", "Dogs can detect cancer by smell alone"),
        ("🦴", "Puppies are born blind, deaf, and toothless"),
        ("🐱", "Cats spend 30–50% of awake time grooming"),
        ("🐠", "Fish feel pain — they're smarter than we think"),
        ("🦮", "Guide dogs can tell when their owner is nervous"),
        ("🐾", "Pets can lower your blood pressure just by being near you"),
        ("🐕", "Dogs' sense of smell is 10,000× stronger than humans'"),
        ("🌙", "Cats are most active at dawn and dusk — crepuscular"),
        ("🐣", "Budgies can recognise over 150 words"),
        ("💤", "Dogs sleep 12–14 hours a day on average"),
        ("🐱", "Cats have a third eyelid — the nictitating membrane"),
        ("🦷", "Dental disease affects 80% of dogs by age 3"),
        ("🐶", "Your dog knows when you're faking happiness"),
        ("🌿", "Catnip makes 50–70% of cats react — it's genetic"),
        ("🐾", "Pets who are logged regularly live longer, healthier lives"),
        ("🩺", "Annual vet visits can add years to your pet's life"),
        ("💛", "Pets who feel known feel loved — log their day"),
    ]

    private var statusBar: some View {
        ZStack {
            let (emoji, text) = taglines[taglineIndex]
            HStack(spacing: 5) {
                Text(emoji)
                    .font(.system(size: 11))
                Text(text)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(PawlyColors.inkSoft)
                    .lineLimit(1)
            }
            .id(taglineIndex)
            .transition(.asymmetric(
                insertion: .opacity.combined(with: .offset(y: 5)),
                removal:   .opacity.combined(with: .offset(y: -5))
            ))
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.vertical, 7)
        .background {
            ZStack {
                Color(.systemBackground)
                Color(red: 1.0, green: 0.97, blue: 0.94).opacity(0.6)
            }
            .overlay(alignment: .top) {
                Rectangle().fill(Color.black.opacity(0.07)).frame(height: 0.5)
            }
            .overlay(alignment: .bottom) {
                Rectangle().fill(Color.black.opacity(0.06)).frame(height: 0.5)
            }
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(7))
                withAnimation(.easeInOut(duration: 0.45)) {
                    taglineIndex = (taglineIndex + 1) % taglines.count
                }
            }
        }
    }

    private var headerBackground: some View {
        ZStack {
            // Frosted glass effect
            Rectangle()
                .fill(.ultraThinMaterial)

            // Subtle warm tint
            Rectangle()
                .fill(Color.white.opacity(0.4))

            // Bottom border
            VStack {
                Spacer()
                Rectangle()
                    .fill(Color.black.opacity(0.06))
                    .frame(height: 0.5)
            }
        }
    }
}

// MARK: - Pet Switcher Sheet

struct PetSwitcherSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var petContext: PetContextStore
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var authService: AuthService

    let pets: [PetDTO]

    @State private var showingAddPet = false
    @State private var petToDelete: PetDTO? = nil

    private var activePet: PetDTO? {
        pets.first { $0.id == petContext.activePetID } ?? pets.first
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Active pet card
                    if let active = activePet {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Active pet")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(PawlyColors.inkSoft)
                                .tracking(0.5)
                                .textCase(.uppercase)

                            activePetCard(active)
                        }
                    }

                    // All pets
                    VStack(alignment: .leading, spacing: 12) {
                        Text("All pets")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(PawlyColors.inkSoft)
                            .tracking(0.5)
                            .textCase(.uppercase)

                        ForEach(pets) { pet in
                            petRow(pet)
                        }

                        // Add pet button
                        addPetButton
                    }
                }
                .padding(20)
            }
            .background(PawlyColors.pastelBg.ignoresSafeArea())
            .navigationTitle("Pets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(PawlyColors.peachAccent)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .sheet(isPresented: $showingAddPet) {
            PBCAddPetSheet(onDismiss: { showingAddPet = false })
        }
        .sheet(item: $petToDelete) { pet in
            DeletePetAuthSheet(pet: pet) {
                petToDelete = nil
            }
            .environmentObject(dataStore)
            .environmentObject(authService)
            .environmentObject(petContext)
        }
    }

    private func activePetCard(_ pet: PetDTO) -> some View {
        HStack(spacing: 14) {
            PetAvatarDTO(pet: pet, size: 64)

            VStack(alignment: .leading, spacing: 4) {
                Text(pet.name)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(PawlyColors.ink)
                Text(Species(rawValue: pet.speciesRaw)?.displayName ?? pet.speciesRaw)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(PawlyColors.inkSoft)
            }

            Spacer()

            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(PawlyColors.peachAccent)

                Menu {
                    Button(role: .destructive) {
                        petToDelete = pet
                    } label: {
                        Label("Delete \(pet.name)", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(PawlyColors.inkSoft.opacity(0.5))
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Color.black.opacity(0.05)))
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(Color(hex: pet.accentHex).opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .stroke(Color(hex: pet.accentHex).opacity(0.3), lineWidth: 1)
        )
    }

    private func petRow(_ pet: PetDTO) -> some View {
        HStack(spacing: 0) {
            Button {
                Haptics.light()
                petContext.setActive(pet)
                dismiss()
            } label: {
                HStack(spacing: 14) {
                    PetAvatarDTO(pet: pet, size: 48)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(pet.name)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(PawlyColors.ink)
                        Text(Species(rawValue: pet.speciesRaw)?.displayName ?? pet.speciesRaw)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(PawlyColors.inkSoft)
                    }

                    Spacer()

                    if pet.id == activePet?.id {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(PawlyColors.peachAccent)
                            .padding(.trailing, 4)
                    }
                }
                .padding(.leading, 14)
                .padding(.vertical, 14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Menu {
                Button(role: .destructive) {
                    petToDelete = pet
                } label: {
                    Label("Delete \(pet.name)", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(PawlyColors.inkSoft.opacity(0.5))
                    .frame(width: 44, height: 44)
            }
            .padding(.trailing, 6)
        }
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
        )
    }

    private var addPetButton: some View {
        Button {
            Haptics.light()
            showingAddPet = true
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(PawlyColors.peachAccentSoft)
                        .frame(width: 48, height: 48)
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(PawlyColors.peachAccent)
                }

                Text("Add another pet")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(PawlyColors.ink)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(PawlyColors.inkSoft.opacity(0.4))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                            .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [5, 3]))
                            .foregroundStyle(Color.black.opacity(0.1))
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Delete Pet Auth Sheet

struct DeletePetAuthSheet: View {
    let pet: PetDTO
    let onDeleted: () -> Void

    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var petContext: PetContextStore

    @State private var password = ""
    @State private var error: String? = nil
    @State private var isDeleting = false
    @FocusState private var passwordFocused: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Warning header
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(PawlyColors.alertSoft)
                            .frame(width: 72, height: 72)
                        Image(systemName: "trash.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(PawlyColors.alert)
                    }
                    .padding(.top, 40)

                    Text("Delete \(pet.name)?")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(PawlyColors.ink)

                    Text("This will permanently remove \(pet.name) and all their records, reminders, and logs. This cannot be undone.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(PawlyColors.inkSoft)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                // Password field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Enter your password to confirm")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(PawlyColors.inkSoft)
                        .tracking(0.5)
                        .textCase(.uppercase)

                    SecureField("Password", text: $password)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(PawlyColors.ink)
                        .focused($passwordFocused)
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(
                                            error != nil ? PawlyColors.alert : Color.black.opacity(0.08),
                                            lineWidth: 1.5
                                        )
                                )
                        )

                    if let error {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.system(size: 12))
                            Text(error)
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundStyle(PawlyColors.alert)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 36)

                Spacer()

                // Action buttons
                VStack(spacing: 12) {
                    Button {
                        Task { await confirmDelete() }
                    } label: {
                        ZStack {
                            if isDeleting {
                                ProgressView().tint(.white)
                            } else {
                                Text("Delete \(pet.name)")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(password.isEmpty || isDeleting
                                      ? PawlyColors.alert.opacity(0.4)
                                      : PawlyColors.alert)
                        )
                    }
                    .disabled(password.isEmpty || isDeleting)
                    .buttonStyle(.plain)

                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(PawlyColors.inkSoft)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                    }
                    .buttonStyle(.plain)
                    .disabled(isDeleting)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .background(PawlyColors.pastelBg.ignoresSafeArea())
            .navigationBarHidden(true)
            .onAppear { passwordFocused = true }
        }
    }

    private func confirmDelete() async {
        guard let email = authService.currentUser?.email else {
            error = "Unable to verify identity. Please sign in again."
            return
        }
        isDeleting = true
        error = nil

        let authenticated = await authService.signIn(email: email, password: password)
        guard authenticated else {
            await MainActor.run {
                isDeleting = false
                error = "Incorrect password. Please try again."
                password = ""
                passwordFocused = true
            }
            return
        }

        await dataStore.deletePet(id: pet.id)

        if petContext.activePetID == pet.id {
            let remaining = dataStore.pets.filter { $0.statusRaw == "active" }
            petContext.setActive(remaining.first)
        }

        await MainActor.run {
            isDeleting = false
            onDeleted()
            dismiss()
        }
    }
}

// MARK: - Notifications Sheet

struct NotificationsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var petContext: PetContextStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    statsSection
                    upcomingSection
                    recentSection
                }
                .padding(20)
            }
            .background(PawlyColors.pastelBg.ignoresSafeArea())
            .navigationTitle("Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(PawlyColors.peachAccent)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Sections

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Today at a glance")

            HStack(spacing: 12) {
                statCard("Tasks due", value: "\(pendingTaskCount)", icon: "checklist", color: PawlyColors.wellnessNutrition)
                statCard("Logs", value: "\(todayLogCount)", icon: "square.and.pencil", color: PawlyColors.peachAccent)
                statCard("Streak", value: "\(currentStreak)d", icon: "flame.fill", color: Color(hex: "#E8B65C"))
            }
        }
    }

    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Upcoming reminders")

            if upcomingReminders.isEmpty {
                emptyCard("No upcoming reminders", "All caught up for the next 7 days!")
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(upcomingReminders.enumerated()), id: \.offset) { _, item in
                        reminderRow(item.reminder, at: item.scheduledAt)
                    }
                }
            }
        }
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Recent activity")

            if recentLogs.isEmpty {
                emptyCard("No recent activity", "Start logging to see activity here")
            } else {
                VStack(spacing: 8) {
                    ForEach(recentLogs.prefix(5)) { log in
                        logRow(log)
                    }
                }
            }
        }
    }

    // MARK: - Row views

    private func reminderRow(_ reminder: ReminderDTO, at date: Date) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(PawlyColors.peachAccentSoft)
                    .frame(width: 36, height: 36)
                Image(systemName: ReminderType(rawValue: reminder.typeRaw)?.sfSymbol ?? "bell.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(PawlyColors.peachAccent)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(reminder.title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(PawlyColors.ink)
                Text(relativeDate(date))
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundStyle(PawlyColors.inkSoft)
            }
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
        )
    }

    private func logRow(_ log: LogEntryDTO) -> some View {
        let kind = LogKind(rawValue: log.kindRaw) ?? .meal
        return HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(PawlyColors.peachAccentSoft)
                    .frame(width: 36, height: 36)
                Image(systemName: kind.sfSymbol)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(PawlyColors.peachAccent)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(log.detail.isEmpty ? kind.displayName : log.detail)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(PawlyColors.ink)
                Text(relativeDate(log.at))
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundStyle(PawlyColors.inkSoft)
            }
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
        )
    }

    private func statCard(_ label: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(color)
            }
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(PawlyColors.ink)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(PawlyColors.inkSoft)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
        )
    }

    private func emptyCard(_ title: String, _ subtitle: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(PawlyColors.inkSoft)
            Text(subtitle)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(PawlyColors.inkSoft.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(Color.white)
        )
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(PawlyColors.inkSoft)
            .tracking(0.5)
            .textCase(.uppercase)
    }

    // MARK: - Data (all scoped to the active pet)

    private var activePetId: UUID? { petContext.activePetID }

    private var petReminderIds: Set<UUID> {
        guard let id = activePetId else { return [] }
        return Set(dataStore.reminders.filter { $0.petId == id }.map(\.id))
    }

    /// Pending (not yet completed) reminder instances today for the active pet.
    private var pendingTaskCount: Int {
        guard let id = activePetId else { return 0 }
        return dataStore.reminderInstancesToday(forPetId: id)
            .filter { $0.statusRaw == "upcoming" }
            .count
    }

    /// Log entries created today for the active pet.
    private var todayLogCount: Int {
        guard let id = activePetId else { return 0 }
        let start = Date().startOfDay
        let end = Date().endOfDay
        return dataStore.logEntries.filter { $0.petId == id && $0.at >= start && $0.at <= end }.count
    }

    /// Current streak for the active pet.
    private var currentStreak: Int {
        guard let id = activePetId else { return 0 }
        return dataStore.streakDays(forPetId: id)
    }

    /// Next 5 upcoming reminder instances (status "upcoming", within 7 days) for the active pet.
    private var upcomingReminders: [(reminder: ReminderDTO, scheduledAt: Date)] {
        let now = Date()
        let sevenDaysLater = Calendar.current.date(byAdding: .day, value: 7, to: now) ?? now
        return dataStore.reminderInstances
            .filter { instance in
                guard let rid = instance.reminderId, petReminderIds.contains(rid) else { return false }
                return instance.statusRaw == "upcoming"
                    && instance.scheduledAt > now
                    && instance.scheduledAt <= sevenDaysLater
            }
            .sorted { $0.scheduledAt < $1.scheduledAt }
            .prefix(5)
            .compactMap { instance -> (ReminderDTO, Date)? in
                guard let reminder = dataStore.reminders.first(where: { $0.id == instance.reminderId }) else { return nil }
                return (reminder, instance.scheduledAt)
            }
    }

    /// Most recent 5 log entries for the active pet.
    private var recentLogs: [LogEntryDTO] {
        guard let id = activePetId else { return [] }
        return dataStore.logEntries
            .filter { $0.petId == id }
            .sorted { $0.at > $1.at }
            .prefix(5)
            .map { $0 }
    }

    // MARK: - Helpers

    private func relativeDate(_ date: Date) -> String {
        let cal = Calendar.current
        let f = DateFormatter()
        if cal.isDateInToday(date) {
            f.dateFormat = "'Today · 'h:mm a"
        } else if cal.isDateInTomorrow(date) {
            f.dateFormat = "'Tomorrow · 'h:mm a"
        } else if cal.isDateInYesterday(date) {
            f.dateFormat = "'Yesterday · 'h:mm a"
        } else {
            f.dateFormat = "EEE, MMM d · h:mm a"
        }
        return f.string(from: date)
    }
}

// MARK: - Settings Sheet

struct SettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var petContext: PetContextStore

    @State private var showingSignOutAlert = false
    @State private var isRefreshing = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    accountSection
                    dataSection
                    signOutSection
                }
                .padding(20)
            }
            .background(PawlyColors.pastelBg.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(PawlyColors.peachAccent)
                }
            }
            .alert("Sign out", isPresented: $showingSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign out", role: .destructive) {
                    Task { await authService.signOut() }
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Sections

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Account")

            VStack(spacing: 0) {
                if let user = authService.currentUser {
                    settingsRow(
                        icon: "envelope",
                        iconColor: PawlyColors.peachAccent,
                        title: "Email",
                        value: user.email ?? "—"
                    )
                    Divider()
                        .padding(.leading, 62)
                        .background(PawlyColors.borderSoft)
                }

                NavigationLink {
                    SettingsPetsView()
                        .environmentObject(dataStore)
                        .environmentObject(petContext)
                        .environmentObject(authService)
                } label: {
                    settingsRow(
                        icon: "pawprint.fill",
                        iconColor: PawlyColors.wellnessNutrition,
                        title: "Pets",
                        value: "\(dataStore.pets.count)",
                        showChevron: true
                    )
                }
                .buttonStyle(.plain)
            }
            .background(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
            )
        }
    }

    private var dataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Data")

            Button {
                Task {
                    isRefreshing = true
                    await dataStore.fetchAllData()
                    isRefreshing = false
                }
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(PawlyColors.sky.opacity(0.12))
                            .frame(width: 36, height: 36)
                        if isRefreshing {
                            ProgressView()
                                .tint(PawlyColors.sky)
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(PawlyColors.sky)
                        }
                    }
                    Text("Refresh data")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(PawlyColors.ink)
                    Spacer()
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
                )
            }
            .buttonStyle(.plain)
            .disabled(isRefreshing)
        }
    }

    private var signOutSection: some View {
        Button {
            showingSignOutAlert = true
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(PawlyColors.alertSoft)
                        .frame(width: 36, height: 36)
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(PawlyColors.alert)
                }
                Text("Sign out")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(PawlyColors.alert)
                Spacer()
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(PawlyColors.inkSoft)
            .tracking(0.5)
            .textCase(.uppercase)
    }

    private func settingsRow(
        icon: String,
        iconColor: Color,
        title: String,
        value: String? = nil,
        showChevron: Bool = false
    ) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(iconColor)
            }
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(PawlyColors.ink)
            Spacer()
            if let value {
                Text(value)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(PawlyColors.inkSoft)
            }
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(PawlyColors.inkSoft.opacity(0.4))
            }
        }
        .padding(14)
    }
}

// MARK: - Settings Pets View

struct SettingsPetsView: View {
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var petContext: PetContextStore
    @EnvironmentObject var authService: AuthService

    @State private var showingAddPet = false
    @State private var petToDelete: PetDTO? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(dataStore.pets) { pet in
                    petRow(pet)
                }
                addPetButton
            }
            .padding(20)
        }
        .background(PawlyColors.pastelBg.ignoresSafeArea())
        .navigationTitle("Pets")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddPet) {
            PBCAddPetSheet(onDismiss: { showingAddPet = false })
        }
        .sheet(item: $petToDelete) { pet in
            DeletePetAuthSheet(pet: pet) {
                petToDelete = nil
            }
            .environmentObject(dataStore)
            .environmentObject(authService)
            .environmentObject(petContext)
        }
    }

    private func petRow(_ pet: PetDTO) -> some View {
        HStack(spacing: 14) {
            PetAvatarDTO(pet: pet, size: 48)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(pet.name)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(PawlyColors.ink)
                    if pet.id == petContext.activePetID {
                        Text("Active")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(PawlyColors.peachAccent)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule().fill(PawlyColors.peachAccentSoft)
                            )
                    }
                }
                Text(Species(rawValue: pet.speciesRaw)?.displayName ?? pet.speciesRaw)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(PawlyColors.inkSoft)
            }

            Spacer()

            Button {
                petToDelete = pet
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(PawlyColors.alert)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(PawlyColors.alertSoft))
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
        )
    }

    private var addPetButton: some View {
        Button {
            Haptics.light()
            showingAddPet = true
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(PawlyColors.peachAccentSoft)
                        .frame(width: 48, height: 48)
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(PawlyColors.peachAccent)
                }
                Text("Add another pet")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(PawlyColors.ink)
                Spacer()
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                            .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [5, 3]))
                            .foregroundStyle(Color.black.opacity(0.1))
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Previews

#Preview("Header") {
    VStack(spacing: 0) {
        PBCAppHeader()
        Spacer()
    }
    .background(PawlyColors.pastelBg.ignoresSafeArea())
    .environmentObject(PreviewSupport.previewPetContext)
    .environmentObject(DataStore.shared)
    .environmentObject(AuthService.shared)
}

#Preview("Settings") {
    SettingsSheet()
        .environmentObject(AuthService.shared)
        .environmentObject(DataStore.shared)
        .environmentObject(PreviewSupport.previewPetContext)
}