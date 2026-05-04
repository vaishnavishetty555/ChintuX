import SwiftUI

/// Pets tab — list, add, switch, memorial section.
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
                VStack(alignment: .leading, spacing: Spacing.m) {
                    header

                    ForEach(active) { pet in
                        NavigationLink(destination: PetProfileViewDTO(pet: pet)) {
                            PetListRowDTO(pet: pet, active: pet.id == petContext.activePetID)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Open \(pet.name)'s profile")
                    }

                    if !lost.isEmpty {
                        Text("Lost")
                            .font(PawlyFont.headingMedium)
                            .foregroundStyle(PawlyColors.alert)
                            .padding(.top, Spacing.s)
                        ForEach(lost) { pet in
                            NavigationLink(destination: PetProfileViewDTO(pet: pet)) {
                                PetListRowDTO(pet: pet, active: false, badge: "Lost")
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if !memorial.isEmpty {
                        Text("In memory")
                            .font(PawlyFont.headingMedium)
                            .foregroundStyle(PawlyColors.slate)
                            .padding(.top, Spacing.s)
                        ForEach(memorial) { pet in
                            NavigationLink(destination: PetProfileViewDTO(pet: pet)) {
                                PetListRowDTO(pet: pet, active: false, badge: "Memorial")
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, Spacing.screenHorizontal)
                .padding(.vertical, Spacing.m)
            }
            .background(PawlyColors.cream.ignoresSafeArea())
            .navigationTitle("Your pets")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button(role: .destructive) {
                            confirmSignOut = true
                        } label: {
                            Label("Sign Out", systemImage: "arrow.backward.square")
                        }
                    } label: {
                        Image(systemName: "person.crop.circle")
                            .tint(PawlyColors.forest)
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        guard active.count < 5 else { return }
                        showingAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .tint(PawlyColors.forest)
                    .disabled(active.count >= 5)
                    .accessibilityHint(active.count >= 5 ? "Limit of 5 pets on the free tier" : "Add a new pet")
                }
            }
            .sheet(isPresented: $showingAdd) {
                OnboardingCoordinator(onComplete: { showingAdd = false })
                    .interactiveDismissDisabled(false)
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

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(active.count)/5 pets")
                    .font(PawlyFont.caption)
                    .foregroundStyle(PawlyColors.slate)
                Text("Tap any pet to see their full profile.")
                    .font(PawlyFont.bodyMedium)
                    .foregroundStyle(PawlyColors.slate)
            }
            Spacer()
        }
        .padding(Spacing.s)
        .background(
            RoundedRectangle(cornerRadius: Radius.small, style: .continuous)
                .fill(PawlyColors.forestLight)
        )
    }
}

struct PetListRowDTO: View {
    let pet: PetDTO
    var active: Bool
    var badge: String? = nil
    @EnvironmentObject var petContext: PetContextStore

    var body: some View {
        HStack(spacing: Spacing.m) {
            PetAvatarDTO(pet: pet, size: 54)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(pet.name)
                        .font(PawlyFont.headingMedium)
                        .foregroundStyle(PawlyColors.ink)
                    if active {
                        Text("Active")
                            .font(.system(size: 10, weight: .semibold))
                            .padding(.horizontal, 7).padding(.vertical, 2)
                            .background(Capsule().fill(PawlyColors.forest))
                            .foregroundStyle(.white)
                    }
                    if let badge {
                        Text(badge)
                            .font(.system(size: 10, weight: .semibold))
                            .padding(.horizontal, 7).padding(.vertical, 2)
                            .background(Capsule().fill(PawlyColors.slate.opacity(0.12)))
                            .foregroundStyle(PawlyColors.slate)
                    }
                }
                Text("\(Species(rawValue: pet.speciesRaw)?.displayName ?? pet.speciesRaw) · \(pet.breed.isEmpty ? "Mixed" : pet.breed) · \(ageDescription)")
                    .font(PawlyFont.caption)
                    .foregroundStyle(PawlyColors.slate)
            }

            Spacer()

            Button {
                Haptics.medium()
                petContext.setActive(pet)
            } label: {
                Image(systemName: active ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(active ? PawlyColors.forest : PawlyColors.sand)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(active ? "Currently active" : "Set as active")
        }
        .padding(Spacing.m)
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(PawlyColors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .stroke(active ? PawlyColors.forest.opacity(0.3) : PawlyColors.sand.opacity(0.3), lineWidth: 0.75)
        )
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

#Preview("Pets") {
    PetsView()
        .environmentObject(PetContextStore())
        .environmentObject(DataStore.shared)
}