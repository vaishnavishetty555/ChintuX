import SwiftUI

/// Pet profile with tabs: Overview, Health, Meds, Logs, Documents.
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
            VStack(alignment: .leading, spacing: 0) {
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
                .padding(.horizontal, Spacing.screenHorizontal)
                .padding(.top, Spacing.m)
            }
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
                        Button { setStatus("active") } label: {
                            Label("Restore", systemImage: "arrow.uturn.backward")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .tint(PawlyColors.forest)
                }
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
        HStack(spacing: Spacing.m) {
            PetAvatarDTO(pet: pet, size: 76)

            VStack(alignment: .leading, spacing: 3) {
                Text(pet.name)
                    .font(PawlyFont.displayMedium)
                    .foregroundStyle(PawlyColors.ink)

                Text("\(Species(rawValue: pet.speciesRaw)?.displayName ?? pet.speciesRaw) · \(pet.breed.isEmpty ? "Mixed" : pet.breed)")
                    .font(PawlyFont.bodyMedium)
                    .foregroundStyle(PawlyColors.slate)

                Text(ageDescription)
                    .font(PawlyFont.caption)
                    .foregroundStyle(PawlyColors.slate)
            }

            Spacer()

            // Status badge
            if pet.statusRaw == "lost" {
                Text("Lost")
                    .font(.system(size: 10, weight: .semibold))
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Capsule().fill(PawlyColors.alert))
                    .foregroundStyle(.white)
            } else if pet.statusRaw == "passed" {
                Text("Memorial")
                    .font(.system(size: 10, weight: .semibold))
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Capsule().fill(PawlyColors.slate.opacity(0.2)))
                    .foregroundStyle(PawlyColors.slate)
            }
        }
        .padding(Spacing.m)
        .background(PawlyColors.surface)
        .overlay(
            Rectangle()
                .fill(PawlyColors.sand.opacity(0.3))
                .frame(height: 0.5),
            alignment: .bottom
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

    // MARK: - Tab bar

    private var tabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(ProfileTab.allCases, id: \.self) { t in
                    Button { withAnimation(.easeInOut(duration: 0.2)) { tab = t } } label: {
                        Text(t.rawValue)
                            .font(.system(size: 12, weight: .semibold))
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(
                                Capsule().fill(tab == t ? PawlyColors.forest : PawlyColors.surface)
                            )
                            .foregroundStyle(tab == t ? .white : PawlyColors.ink)
                            .overlay(
                                Capsule().stroke(
                                    tab == t ? PawlyColors.forest : PawlyColors.sand.opacity(0.4),
                                    lineWidth: 0.75
                                )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.vertical, Spacing.s)
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
            cardSection("Vaccinations") {
                let vaccines = dataStore.reminders(forPetId: pet.id).filter { $0.typeRaw == "vaccination" }
                if vaccines.isEmpty {
                    Text("No vaccination reminders yet.").font(PawlyFont.bodyMedium).foregroundStyle(PawlyColors.slate)
                } else {
                    ForEach(vaccines) { v in
                        HStack {
                            Text(v.title).font(PawlyFont.bodyMedium).foregroundStyle(PawlyColors.ink)
                            Spacer()
                            if let recurrence = Recurrence(rawString: v.recurrenceRaw) {
                                Text(recurrence.displayDescription).font(PawlyFont.caption).foregroundStyle(PawlyColors.slate)
                            }
                        }
                    }
                }
            }
            cardSection("Conditions") {
                Text(pet.ongoingConditionsText.isEmpty ? "None recorded." : pet.ongoingConditionsText)
                    .font(PawlyFont.bodyMedium)
                    .foregroundStyle(PawlyColors.slate)
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
                cardSection("Logs") {
                    Text("No logs yet. Use the + button to log meals, meds, walks.")
                        .font(PawlyFont.bodyMedium).foregroundStyle(PawlyColors.slate)
                }
            } else {
                ForEach(sorted) { log in
                    HStack(spacing: Spacing.m) {
                        if let kind = LogKind(rawValue: log.kindRaw) {
                            ZStack {
                                Circle().fill(PawlyColors.forestLight).frame(width: 34, height: 34)
                                Image(systemName: kind.sfSymbol)
                                    .font(.system(size: 14))
                                    .foregroundStyle(PawlyColors.forest)
                            }
                        }
                        VStack(alignment: .leading, spacing: 1) {
                            Text("\(LogKind(rawValue: log.kindRaw)?.displayName ?? "Log"): \(log.detail.isEmpty ? "—" : log.detail)")
                                .font(PawlyFont.bodyMedium)
                                .foregroundStyle(PawlyColors.ink)
                            Text(log.at, format: .dateTime.month(.abbreviated).day().hour().minute())
                                .font(PawlyFont.caption)
                                .foregroundStyle(PawlyColors.slate)
                        }
                        Spacer()
                    }
                    .padding(Spacing.s)
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
        }
    }

    private var documentsTab: some View {
        VaultHomeViewDTO(pet: pet)
    }

    @ViewBuilder
    private func infoRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label).font(PawlyFont.caption).foregroundStyle(PawlyColors.slate)
            Spacer()
            Text(value).font(PawlyFont.bodyMedium).foregroundStyle(PawlyColors.ink)
        }
        .padding(Spacing.m)
        .background(
            RoundedRectangle(cornerRadius: Radius.small, style: .continuous)
                .fill(PawlyColors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.small, style: .continuous)
                .stroke(PawlyColors.sand.opacity(0.4), lineWidth: 0.75)
        )
    }

    @ViewBuilder
    private func cardSection(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title)
                .font(PawlyFont.headingMedium)
                .foregroundStyle(PawlyColors.ink)
            content()
        }
        .padding(Spacing.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(PawlyColors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .stroke(PawlyColors.sand.opacity(0.4), lineWidth: 0.75)
        )
    }

    private func setStatus(_ newStatus: String) {
        Task {
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

// MARK: - Vault Home View DTO

struct VaultHomeViewDTO: View {
    let pet: PetDTO
    @EnvironmentObject var dataStore: DataStore

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            let docs = dataStore.documents(forPetId: pet.id)
            if docs.isEmpty {
                VStack(spacing: Spacing.s) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(PawlyColors.forest)
                    Text("No documents yet")
                        .font(PawlyFont.headingMedium)
                        .foregroundStyle(PawlyColors.ink)
                    Text("Upload vaccine cards, prescriptions, and more.")
                        .font(PawlyFont.bodyMedium)
                        .foregroundStyle(PawlyColors.slate)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.xl)
            } else {
                ForEach(docs) { doc in
                    HStack(spacing: Spacing.m) {
                        ZStack {
                            Circle().fill(PawlyColors.forestLight).frame(width: 36, height: 36)
                            Image(systemName: DocumentType(rawValue: doc.documentTypeRaw)?.sfSymbol ?? "doc.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(PawlyColors.forest)
                        }
                        VStack(alignment: .leading, spacing: 1) {
                            Text(doc.title).font(PawlyFont.bodyMedium).foregroundStyle(PawlyColors.ink)
                            if let type = DocumentType(rawValue: doc.documentTypeRaw) {
                                Text(type.displayName).font(PawlyFont.caption).foregroundStyle(PawlyColors.slate)
                            }
                        }
                        Spacer()
                    }
                    .padding(Spacing.s)
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
        }
    }
}