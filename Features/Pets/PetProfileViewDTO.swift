import SwiftUI

/// PRD §6.7 — Pet profile with tabs: Overview, Health, Meds, Logs, Documents.
struct PetProfileViewDTO: View {
    let pet: PetDTO
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) private var dismiss

    enum ProfileTab: String, CaseIterable {
        case overview = "Overview", health = "Health", meds = "Meds", logs = "Logs", documents = "Documents"
    }
    @State private var tab: ProfileTab = .overview
    @State private var confirmPassed = false
    @State private var confirmLost = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.m) {
                hero
                tabBar

                Group {
                    switch tab {
                    case .overview:  overviewTab
                    case .health:    healthTab
                    case .meds:      medsTab
                    case .logs:      logsTab
                    case .documents: documentsTab
                    }
                }
            }
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.vertical, Spacing.m)
        }
        .background(PawlyColors.cream.ignoresSafeArea())
        .navigationTitle(pet.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button(role: .destructive) { confirmLost = true } label: {
                        Label("Mark as lost", systemImage: "mappin.and.ellipse")
                    }
                    Button(role: .destructive) { confirmPassed = true } label: {
                        Label("Mark as passed", systemImage: "leaf.fill")
                    }
                    if pet.statusRaw != "active" {
                        Button { setStatus("active") } label: { Label("Restore", systemImage: "arrow.uturn.backward") }
                    }
                } label: { Image(systemName: "ellipsis.circle").tint(PawlyColors.forest) }
            }
        }
        .alert("Mark \(pet.name) as lost?",
               isPresented: $confirmLost) {
            Button("Cancel", role: .cancel) {}
            Button("Mark lost", role: .destructive) { setStatus("lost") }
        } message: {
            Text("You'll be able to share a found-my-pet card with your photo and contact.")
        }
        .alert("Mark \(pet.name) as passed?",
               isPresented: $confirmPassed) {
            Button("Cancel", role: .cancel) {}
            Button("Mark passed", role: .destructive) { setStatus("passed") }
        } message: {
            Text("Reminders will stop. \(pet.name)'s history will be kept in a Memorial section.")
        }
    }

    // MARK: - Hero

    private var hero: some View {
        PawlyCard {
            VStack(alignment: .leading, spacing: Spacing.s) {
                HStack(spacing: Spacing.m) {
                    PetAvatarDTO(pet: pet, size: 84)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(pet.name).font(PawlyFont.displayMedium).foregroundStyle(PawlyColors.ink)
                        Text("\(Species(rawValue: pet.speciesRaw)?.displayName ?? pet.speciesRaw) • \(pet.breed.isEmpty ? "Mixed" : pet.breed)")
                            .font(PawlyFont.bodyMedium)
                            .foregroundStyle(PawlyColors.slate)
                        Text(ageDescription).font(PawlyFont.caption).foregroundStyle(PawlyColors.slate)
                    }
                    Spacer()
                }
                if pet.statusRaw == "lost" {
                    Text("Lost — please help")
                        .font(PawlyFont.caption)
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(Capsule().fill(PawlyColors.alert))
                        .foregroundStyle(.white)
                }
                if pet.statusRaw == "passed" {
                    Text("In loving memory")
                        .font(PawlyFont.caption)
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(Capsule().fill(PawlyColors.slate.opacity(0.2)))
                        .foregroundStyle(PawlyColors.slate)
                }
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

    // MARK: - Tab bar

    private var tabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(ProfileTab.allCases, id: \.self) { t in
                    Button { tab = t } label: {
                        Text(t.rawValue)
                            .font(PawlyFont.caption)
                            .padding(.horizontal, Spacing.s).padding(.vertical, 8)
                            .background(
                                Capsule().fill(tab == t ? PawlyColors.forest : PawlyColors.surface)
                            )
                            .foregroundStyle(tab == t ? .white : PawlyColors.ink)
                            .overlay(Capsule().stroke(PawlyColors.sand, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Tabs

    private var overviewTab: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            infoRow("Weight", value: pet.weightKg.map { "\(String(format: "%.1f", $0)) kg" } ?? "—")
            infoRow("Sex", value: PetSex(rawValue: pet.sexRaw)?.displayName ?? "Unknown")
            infoRow("Neutered", value: pet.neutered ? "Yes" : "No")
            infoRow("Allergies", value: pet.allergiesText.isEmpty ? "None recorded" : pet.allergiesText)
            infoRow("Vet", value: pet.vetName.isEmpty ? "Not set" : pet.vetName)
        }
    }

    private var healthTab: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            PawlyCard {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Vaccinations").font(PawlyFont.headingMedium)
                    let vaccines = dataStore.reminders(forPetId: pet.id).filter { $0.typeRaw == "vaccination" }
                    if vaccines.isEmpty {
                        Text("No vaccination reminders yet.").font(PawlyFont.bodyMedium).foregroundStyle(PawlyColors.slate)
                    } else {
                        ForEach(vaccines) { v in
                            HStack {
                                Text(v.title).font(PawlyFont.bodyMedium).foregroundStyle(PawlyColors.ink)
                                Spacer()
                                if let recurrence = Recurrence(rawString: v.recurrenceRaw) {
                                    Text(recurrence.displayDescription)
                                        .font(PawlyFont.caption).foregroundStyle(PawlyColors.slate)
                                }
                            }
                        }
                    }
                }
            }
            PawlyCard {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Conditions").font(PawlyFont.headingMedium)
                    Text(pet.ongoingConditionsText.isEmpty ? "None recorded." : pet.ongoingConditionsText)
                        .font(PawlyFont.bodyMedium)
                        .foregroundStyle(PawlyColors.slate)
                }
            }
        }
    }

    private var medsTab: some View {
        RemindersListViewDTO(pet: pet)
            .frame(minHeight: 300)
    }

    private var logsTab: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            let sorted = dataStore.logEntries(forPetId: pet.id).sorted(by: { $0.at > $1.at })
            if sorted.isEmpty {
                PawlyCard {
                    Text("No logs yet. Use the + button to log meals, meds, walks.")
                        .font(PawlyFont.bodyMedium).foregroundStyle(PawlyColors.slate)
                }
            } else {
                ForEach(sorted) { log in
                    PawlyCard {
                        HStack(spacing: Spacing.m) {
                            if let kind = LogKind(rawValue: log.kindRaw) {
                                Image(systemName: kind.sfSymbol).foregroundStyle(PawlyColors.forest)
                            }
                            VStack(alignment: .leading) {
                                Text("\(LogKind(rawValue: log.kindRaw)?.displayName ?? "Log"): \(log.detail.isEmpty ? "—" : log.detail)")
                                    .font(PawlyFont.bodyMedium)
                                Text(log.at, format: .dateTime.month(.abbreviated).day().hour().minute())
                                    .font(PawlyFont.caption).foregroundStyle(PawlyColors.slate)
                            }
                            Spacer()
                        }
                    }
                }
            }
        }
    }

    private var documentsTab: some View {
        VaultHomeViewDTO(pet: pet)
    }

    @ViewBuilder
    private func infoRow(_ label: String, value: String) -> some View {
        PawlyCard {
            HStack {
                Text(label).font(PawlyFont.caption).foregroundStyle(PawlyColors.slate)
                Spacer()
                Text(value).font(PawlyFont.bodyMedium).foregroundStyle(PawlyColors.ink)
            }
        }
    }

    private func setStatus(_ newStatus: String) {
        Task {
            var updatedPet = pet
            // Create new pet with updated status - we need to recreate the DTO
            // This is a simplified version - in production, you'd want a proper update method
            let dto = PetDTO(
                id: pet.id,
                name: pet.name,
                speciesRaw: pet.speciesRaw,
                breed: pet.breed,
                dateOfBirth: pet.dateOfBirth,
                weightKg: pet.weightKg,
                sexRaw: pet.sexRaw,
                neutered: pet.neutered,
                allergiesText: pet.allergiesText,
                ongoingConditionsText: pet.ongoingConditionsText,
                accentHex: pet.accentHex,
                photoURL: pet.photoURL,
                statusRaw: newStatus,
                markedPassedAt: newStatus == "passed" ? Date() : pet.markedPassedAt,
                markedLostAt: newStatus == "lost" ? Date() : pet.markedLostAt,
                vetName: pet.vetName,
                vetPhone: pet.vetPhone,
                createdAt: pet.createdAt,
                userId: pet.userId
            )
            await dataStore.updatePet(dto)
        }
    }
}

// MARK: - Vault Home View DTO (Placeholder)

struct VaultHomeViewDTO: View {
    let pet: PetDTO
    @EnvironmentObject var dataStore: DataStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            let docs = dataStore.documents(forPetId: pet.id)
            if docs.isEmpty {
                PawlyCard {
                    Text("No documents yet. Upload vaccine cards, prescriptions, and more.")
                        .font(PawlyFont.bodyMedium).foregroundStyle(PawlyColors.slate)
                }
            } else {
                ForEach(docs) { doc in
                    PawlyCard {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(doc.title).font(PawlyFont.bodyMedium)
                                if let type = DocumentType(rawValue: doc.documentTypeRaw) {
                                    Text(type.displayName).font(PawlyFont.caption).foregroundStyle(PawlyColors.slate)
                                }
                            }
                            Spacer()
                        }
                    }
                }
            }
        }
    }
}
