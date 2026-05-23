import SwiftUI

/// Pets tab — pastel design with active pets, lost and memorial sections.
struct PetsView: View {
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var petContext: PetContextStore
    @EnvironmentObject var authService: AuthService
    @State private var showingAdd = false
    @State private var confirmSignOut = false

    private var active: [PetDTO] { dataStore.pets.filter { $0.statusRaw == "active" } }
    private var memorial: [PetDTO] { dataStore.pets.filter { $0.statusRaw == "passed" } }
    private var lost: [PetDTO] { dataStore.pets.filter { $0.statusRaw == "lost" } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your pets")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(PawlyColors.ink)
                        Text(active.count == 0
                             ? "Add your first pet to get started."
                             : "Tap a pet to manage their care.")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(PawlyColors.inkSoft)
                    }
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .padding(.top, Spacing.m)
                    .padding(.bottom, Spacing.xl)

                    // Add Pet button
                    Button { showingAdd = true } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(PawlyColors.peachAccentSoft)
                                    .frame(width: 44, height: 44)
                                Image(systemName: "plus")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(PawlyColors.peachAccent)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Add a pet")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(PawlyColors.ink)
                                Text("Welcome a new family member")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(PawlyColors.inkSoft)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(PawlyColors.inkSoft)
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: Radius.cardLg, style: .continuous)
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .padding(.bottom, Spacing.xl)

                    // Active pets
                    if !active.isEmpty {
                        Text("Active")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(PawlyColors.inkSoft)
                            .tracking(0.5)
                            .textCase(.uppercase)
                            .padding(.horizontal, Spacing.screenHorizontal)
                            .padding(.bottom, Spacing.m)

                        VStack(spacing: 10) {
                            ForEach(active) { pet in
                                NavigationLink(destination: PetProfileViewDTO(pet: pet)) {
                                    PetsPetRow(pet: pet, active: pet.id == petContext.activePetID)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Open \(pet.name)'s profile")
                            }
                        }
                        .padding(.horizontal, Spacing.screenHorizontal)
                    }

                    // Lost section
                    if !lost.isEmpty {
                        Text("Lost")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(PawlyColors.alert)
                            .tracking(0.5)
                            .textCase(.uppercase)
                            .padding(.horizontal, Spacing.screenHorizontal)
                            .padding(.top, Spacing.xl)
                            .padding(.bottom, Spacing.m)

                        VStack(spacing: 10) {
                            ForEach(lost) { pet in
                                NavigationLink(destination: PetProfileViewDTO(pet: pet)) {
                                    PetsPetRow(pet: pet, active: false, badge: "Lost")
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, Spacing.screenHorizontal)
                    }

                    // Memorial section
                    if !memorial.isEmpty {
                        Text("In memory")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(PawlyColors.slate)
                            .tracking(0.5)
                            .textCase(.uppercase)
                            .padding(.horizontal, Spacing.screenHorizontal)
                            .padding(.top, Spacing.xl)
                            .padding(.bottom, Spacing.m)

                        VStack(spacing: 10) {
                            ForEach(memorial) { pet in
                                NavigationLink(destination: PetProfileViewDTO(pet: pet)) {
                                    PetsPetRow(pet: pet, active: false, badge: "Memorial")
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, Spacing.screenHorizontal)
                    }

                    // Free tier indicator
                    if active.count < 5 {
                        HStack(spacing: 6) {
                            Text("\(active.count) of 5 pets on free plan")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(PawlyColors.inkSoft.opacity(0.7))
                            Spacer()
                        }
                        .padding(.horizontal, Spacing.screenHorizontal)
                        .padding(.top, Spacing.xl)
                    }

                    // Sign out row
                    Button {
                        confirmSignOut = true
                    } label: {
                        HStack(spacing: Spacing.m) {
                            Image(systemName: "arrow.backward.square")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(PawlyColors.alert)
                            Text("Sign Out")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(PawlyColors.alert)
                            Spacer()
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                                .fill(PawlyColors.alertSoft)
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .padding(.top, Spacing.xl)

                    Color.clear.frame(height: 120)
                }
            }
            .scrollIndicators(.hidden)
            .background(PawlyColors.pastelBg.ignoresSafeArea())
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        Button {
                            guard active.count < 5 else { return }
                            showingAdd = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(PawlyColors.peachAccent)
                        }
                        .disabled(active.count >= 5)

                        Menu {
                            Button(role: .destructive) {
                                confirmSignOut = true
                            } label: {
                                Label("Sign Out", systemImage: "arrow.backward.square")
                            }
                        } label: {
                            Image(systemName: "person.crop.circle")
                                .font(.system(size: 18))
                                .foregroundStyle(PawlyColors.inkSoft)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAdd) {
                PBCAddPetSheet(onDismiss: { showingAdd = false })
            }
            .refreshable {
                await dataStore.fetchAllData()
            }
            .alert("Sign Out?", isPresented: $confirmSignOut) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    Task { await authService.signOut() }
                }
            } message: {
                Text("You'll need to sign in again to access your pets.")
            }
        }
    }
}

// MARK: - Pet Row

private struct PetsPetRow: View {
    let pet: PetDTO
    var active: Bool = false
    var badge: String? = nil
    @EnvironmentObject var petContext: PetContextStore

    var body: some View {
        HStack(spacing: Spacing.m) {
            PetAvatarDTO(pet: pet, size: 56)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(pet.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(PawlyColors.ink)

                    if active {
                        Text("Active")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(PawlyColors.peachAccent))
                            .foregroundStyle(.white)
                    }

                    if let badge {
                        Text(badge)
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(PawlyColors.inkSoft.opacity(0.1)))
                            .foregroundStyle(PawlyColors.inkSoft)
                    }
                }

                Text(petSubtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(PawlyColors.inkSoft)
            }

            Spacer()

            Button {
                Haptics.medium()
                petContext.setActive(pet)
            } label: {
                Image(systemName: active ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(active ? PawlyColors.peachAccent : PawlyColors.inkSoft.opacity(0.3))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(active ? "Currently active" : "Set as active")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: Radius.cardLg, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.cardLg, style: .continuous)
                .stroke(active ? PawlyColors.peachAccent.opacity(0.2) : PawlyColors.borderSoft,
                        lineWidth: active ? 1 : 0.5)
        )
    }

    private var petSubtitle: String {
        let species = Species(rawValue: pet.speciesRaw)?.displayName ?? pet.speciesRaw
        let breed = pet.breed.isEmpty ? "Mixed" : pet.breed
        return "\(species)  ·  \(breed)  ·  \(ageDescription)"
    }

    private var ageDescription: String {
        guard let dob = pet.dateOfBirth else { return "Age unknown" }
        let comps = Calendar.current.dateComponents([.year, .month], from: dob, to: .now)
        let y = comps.year ?? 0
        let m = comps.month ?? 0
        if y == 0 { return "\(max(0, m))mo" }
        if m == 0 { return "\(y)y" }
        return "\(y)y \(m)mo"
    }
}

// MARK: - Add Pet Sheet

struct PBCAddPetSheet: View {
    let onDismiss: () -> Void
    @EnvironmentObject var dataStore: DataStore

    @State private var step: Int = 0
    @State private var species: String = "cat"
    @State private var name: String = ""
    @State private var breed: String = ""
    @State private var bday: String = ""
    @State private var weight: String = ""
    @State private var indoor: Bool = true
    @State private var spayed: Bool = true
    @State private var chip: String = ""

    private let speciesOptions = [
        ("cat", "Cat", "🐱", Color(hex: "#FFE2D4")),
        ("dog", "Dog", "🐶", Color(hex: "#FAEAC4")),
        ("bird", "Bird", "🦜", Color(hex: "#D9F0E7")),
        ("rabbit", "Rabbit", "🐰", Color(hex: "#FCE3EA")),
        ("hamster", "Small", "🐹", Color(hex: "#E6DFF6")),
        ("fish", "Fish", "🐠", Color(hex: "#DCEDF5")),
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Top bar with step indicator
                HStack {
                    Button {
                        if step == 0 { onDismiss() } else { step -= 1 }
                    } label: {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 36, height: 36)
                            .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
                            .overlay(
                                Image(systemName: step == 0 ? "xmark" : "chevron.left")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(PawlyColors.ink)
                            )
                    }

                    Spacer()

                    HStack(spacing: 5) {
                        ForEach(0..<4, id: \.self) { i in
                            RoundedRectangle(cornerRadius: 3)
                                .fill(i <= step ? PawlyColors.peachAccent : Color.black.opacity(0.1))
                                .frame(width: i == step ? 24 : 8, height: 6)
                                .animation(.spring(response: 0.25), value: step)
                        }
                    }

                    Spacer()

                    Color.clear.frame(width: 36)
                }
                .padding(.horizontal, 20)
                .padding(.top, Spacing.m)

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        switch step {
                        case 0:
                            stepOne
                        case 1:
                            stepTwo
                        case 2:
                            stepThree
                        case 3:
                            stepFour
                        default:
                            EmptyView()
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }

                // Footer button
                VStack(spacing: 0) {
                    Button {
                        if step == 3 { addPet() } else { nextStep() }
                    } label: {
                        Text(step == 3 ? "Add to my pets ✨" : "Continue")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(
                                LinearGradient(
                                    colors: [PawlyColors.peachAccent, PawlyColors.peachAccentDeep],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .shadow(color: PawlyColors.peachAccent.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .background(PawlyColors.pastelBg.ignoresSafeArea())
        }
    }

    private var stepOne: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Step 1 of 4")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(PawlyColors.inkSoft)
                .tracking(0.5)
                .textCase(.uppercase)
            Text("Who are we welcoming?")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(PawlyColors.ink)
                .tracking(-0.01)
            Text("Pick the species — we'll tailor everything to them.")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(PawlyColors.inkSoft)
                .padding(.top, 2)
                .padding(.bottom, 18)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(speciesOptions, id: \.0) { opt in
                    Button {
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                            species = opt.0
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Text(opt.2)
                                .font(.system(size: 36))
                            Text(opt.1)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(PawlyColors.ink)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .padding(.horizontal, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(species == opt.0 ? opt.3 : Color.white)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(species == opt.0 ? PawlyColors.peachAccent : Color.clear, lineWidth: 2)
                        )
                        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
                        .scaleEffect(species == opt.0 ? 1.03 : 1)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var stepTwo: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Step 2 of 4")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(PawlyColors.inkSoft)
                .tracking(0.5)
                .textCase(.uppercase)
            Text("What's their name?")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(PawlyColors.ink)
                .tracking(-0.01)
                .padding(.bottom, 8)

            PBCFormField(label: "Name", placeholder: "e.g. Mochi", text: $name)
            PBCFormField(label: "Breed", placeholder: "e.g. Persian", text: $breed)
            PBCFormField(label: "Birthday", placeholder: "MM / DD / YYYY", text: $bday)
        }
    }

    private var stepThree: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Step 3 of 4")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(PawlyColors.inkSoft)
                .tracking(0.5)
                .textCase(.uppercase)
            Text("A few details")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(PawlyColors.ink)
                .tracking(-0.01)
                .padding(.bottom, 8)

            PBCFormField(label: "Weight", placeholder: species == "cat" ? "4.5 kg" : species == "dog" ? "20 kg" : "120 g", text: $weight)

            VStack(alignment: .leading, spacing: 6) {
                Text("Lifestyle")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(PawlyColors.inkSoft)
                    .tracking(0.5)
                    .textCase(.uppercase)
                PBCSegmentedBool(selected: $indoor)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Spayed / neutered")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(PawlyColors.inkSoft)
                    .tracking(0.5)
                    .textCase(.uppercase)
                PBCSegmentedBool(selected: $spayed, trueLabel: "Yes", falseLabel: "No")
            }

            PBCFormField(label: "Microchip ID (optional)", placeholder: "15-digit ID", text: $chip)
        }
    }

    private var stepFour: some View {
        VStack(alignment: .center, spacing: 0) {
            let selected = speciesOptions.first { $0.0 == species } ?? speciesOptions[0]
            ZStack {
                Circle()
                    .fill(selected.3)
                    .frame(width: 120, height: 120)
                Text(selected.2)
                    .font(.system(size: 64))
            }
            .padding(.top, 24)

            Text("Welcome, \(name.isEmpty ? "friend" : name)! ✨")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(PawlyColors.ink)
                .tracking(-0.01)
                .padding(.top, 20)

            Text("We've set up a wellness plan, vaccine schedule and document vault tailored for a \(breed.isEmpty ? species : breed).")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(PawlyColors.inkSoft)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.top, 8)

            VStack(spacing: 8) {
                let itemIcons = ["shield.fill", "pills.fill", "fork.knife", "lock.doc.fill"]
                let itemLabels = ["Vaccine schedule generated", "Medication reminders ready", "Daily care routine drafted", "Pet vault created"]
                let itemTones = [4, 0, 1, 2]
                ForEach(0..<4, id: \.self) { idx in
                    let icon = itemIcons[idx]
                    let label = itemLabels[idx]
                    let toneInt = itemTones[idx]
                    let tone = PawlyColors.CardTone(rawValue: toneInt) ?? .peach
                    HStack(spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(tone.bg)
                                .frame(width: 32, height: 32)
                            Image(systemName: icon)
                                .font(.system(size: 16))
                                .foregroundStyle(tone.tint)
                        }
                        Text(label)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(PawlyColors.ink)
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(Color(hex: "#5DBFA0"))
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
                    )
                }
            }
            .padding(.top, 24)
            .padding(.horizontal, 4)
        }
    }

    private func nextStep() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            step = min(step + 1, 3)
        }
    }

    private func addPet() {
        Task {
            let parsedBday = parseBirthday()
            let sex: PetSex = spayed ? .female : .male
            let accentColor = accentColorFor(species)
            if let _ = await dataStore.createPet(
                name: name.isEmpty ? "My pet" : name,
                species: Species(rawValue: species) ?? .cat,
                breed: breed,
                dateOfBirth: parsedBday,
                sex: sex,
                accentHex: accentColor
            ) {
                await MainActor.run { onDismiss() }
            } else {
                await MainActor.run { onDismiss() }
            }
        }
    }

    private func parseBirthday() -> Date? {
        let parts = bday.split(separator: "/").map { $0.trimmingCharacters(in: .whitespaces) }
        guard parts.count == 3,
              let month = Int(parts[0]),
              let day = Int(parts[1]),
              let year = Int(parts[2]) else { return nil }
        var comps = DateComponents()
        comps.month = month
        comps.day = day
        comps.year = year
        return Calendar.current.date(from: comps)
    }

    private func parseWeight() -> Double? {
        let cleaned = weight.replacingOccurrences(of: "kg", with: "")
            .replacingOccurrences(of: "g", with: "")
            .trimmingCharacters(in: .whitespaces)
        return Double(cleaned)
    }

    private func accentColorFor(_ species: String) -> String {
        switch species {
        case "cat":   return "#FFE2D4"
        case "dog":   return "#FAEAC4"
        case "bird":  return "#D9F0E7"
        case "rabbit": return "#FCE3EA"
        case "hamster": return "#E6DFF6"
        case "fish":  return "#DCEDF5"
        default:      return "#FFE2D4"
        }
    }
}

// MARK: - Form Field

private struct PBCFormField: View {
    let label: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(PawlyColors.inkSoft)
                .tracking(0.5)
                .textCase(.uppercase)
            TextField(placeholder, text: $text)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(PawlyColors.ink)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.black.opacity(0.08), lineWidth: 1.5)
                        )
                )
        }
    }
}

// MARK: - Segmented Control

private struct PBCSegmentedBool: View {
    @Binding var selected: Bool
    var trueLabel: String = "Indoor"
    var falseLabel: String = "Outdoor"

    var body: some View {
        HStack(spacing: 0) {
            ForEach([trueLabel, falseLabel], id: \.self) { label in
                let isSelected = (label == trueLabel) == selected
                Button {
                    selected = label == trueLabel
                } label: {
                    Text(label)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(isSelected ? .white : PawlyColors.ink)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(isSelected ? PawlyColors.peachAccent : Color.clear)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.black.opacity(0.08), lineWidth: 1.5)
                )
        )
    }
}

#Preview("Pets") {
    PetsView()
        .environmentObject(PetContextStore())
        .environmentObject(DataStore.shared)
}