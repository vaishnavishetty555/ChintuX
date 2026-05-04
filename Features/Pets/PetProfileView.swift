import SwiftUI
import SwiftData

/// PRD §6.7 — Pet profile with tabs: Overview, Health, Meds, Logs, Documents.
struct PetProfileView: View {
    let pet: Pet
    @Environment(\.modelContext) private var modelContext
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
                    if pet.status != .active {
                        Button { setStatus(.active) } label: {
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
            Button("Mark lost", role: .destructive) { setStatus(.lost) }
        } message: {
            Text("You'll be able to share a found-my-pet card with your photo and contact.")
        }
        .alert("Mark \(pet.name) as passed?",
               isPresented: $confirmPassed) {
            Button("Cancel", role: .cancel) {}
            Button("Mark passed", role: .destructive) { setStatus(.passed) }
        } message: {
            Text("Reminders will stop. \(pet.name)'s history will be kept in a Memorial section.")
        }
    }

    // MARK: - Hero

    private var hero: some View {
        HStack(spacing: Spacing.m) {
            PetAvatarDTO(pet: PetDTO(from: pet), size: 76)

            VStack(alignment: .leading, spacing: 3) {
                Text(pet.name)
                    .font(PawlyFont.displayMedium)
                    .foregroundStyle(PawlyColors.ink)

                Text("\(pet.species.displayName) · \(pet.breed.isEmpty ? "Mixed" : pet.breed)")
                    .font(PawlyFont.bodyMedium)
                    .foregroundStyle(PawlyColors.slate)

                Text(pet.ageDescription)
                    .font(PawlyFont.caption)
                    .foregroundStyle(PawlyColors.slate)
            }

            Spacer()

            if pet.status == .lost {
                Text("Lost")
                    .font(.system(size: 10, weight: .semibold))
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Capsule().fill(PawlyColors.alert))
                    .foregroundStyle(.white)
            } else if pet.status == .passed {
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
            infoRow("Weight", value: pet.weightKg.map { "\($0) kg" } ?? "—")
            infoRow("Sex", value: pet.sex.displayName)
            infoRow("Neutered", value: pet.neutered ? "Yes" : "No")
            infoRow("Allergies", value: pet.allergiesText.isEmpty ? "None recorded" : pet.allergiesText)
            infoRow("Vet", value: pet.vetName.isEmpty ? "Not set" : pet.vetName)
        }
    }

    private var healthTab: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            cardSection("Vaccinations") {
                let vaccines = pet.reminders.filter { $0.type == .vaccination }
                if vaccines.isEmpty {
                    Text("No vaccination reminders yet.").font(PawlyFont.bodyMedium).foregroundStyle(PawlyColors.slate)
                } else {
                    ForEach(vaccines) { v in
                        HStack {
                            Text(v.title).font(PawlyFont.bodyMedium).foregroundStyle(PawlyColors.ink)
                            Spacer()
                            Text(v.recurrence.displayDescription)
                                .font(PawlyFont.caption).foregroundStyle(PawlyColors.slate)
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
        RemindersListView(pet: pet)
            .frame(minHeight: 300)
    }

    private var logsTab: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            let sorted = pet.logEntries.sorted(by: { $0.at > $1.at })
            if sorted.isEmpty {
                cardSection("Logs") {
                    Text("No logs yet. Use the + button to log meals, meds, walks.")
                        .font(PawlyFont.bodyMedium).foregroundStyle(PawlyColors.slate)
                }
            } else {
                ForEach(sorted) { log in
                    HStack(spacing: Spacing.m) {
                        ZStack {
                            Circle().fill(PawlyColors.forestLight).frame(width: 34, height: 34)
                            Image(systemName: log.kind.sfSymbol)
                                .font(.system(size: 14))
                                .foregroundStyle(PawlyColors.forest)
                        }
                        VStack(alignment: .leading, spacing: 1) {
                            Text("\(log.kind.displayName): \(log.detail.isEmpty ? "—" : log.detail)")
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
        VaultHomeView(pet: pet)
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

    private func setStatus(_ new: PetStatus) {
        pet.status = new
        switch new {
        case .lost:   pet.markedLostAt = .now
        case .passed: pet.markedPassedAt = .now
        case .active: break
        }
        try? modelContext.save()
    }
}

// MARK: - Weight curve (simple)

private struct WeightCurveCard: View {
    let pet: Pet

    private var weightLogs: [LogEntry] {
        pet.logEntries
            .filter { $0.kind == .weight && $0.numericValue != nil }
            .sorted(by: { $0.at < $1.at })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Weight curve").font(PawlyFont.headingMedium)
            if weightLogs.count < 2 {
                Text("Log weight over time to see a curve here.")
                    .font(PawlyFont.bodyMedium).foregroundStyle(PawlyColors.slate)
            } else {
                GeometryReader { geo in
                    let values = weightLogs.compactMap { $0.numericValue }
                    let minV = (values.min() ?? 0) - 0.3
                    let maxV = (values.max() ?? 1) + 0.3
                    let stepX = geo.size.width / CGFloat(max(1, values.count - 1))
                    Path { path in
                        for (i, v) in values.enumerated() {
                            let x = CGFloat(i) * stepX
                            let normalized = (v - minV) / max(0.001, (maxV - minV))
                            let y = geo.size.height * (1 - CGFloat(normalized))
                            if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                            else { path.addLine(to: CGPoint(x: x, y: y)) }
                        }
                    }
                    .stroke(PawlyColors.forest, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                }
                .frame(height: 80)
            }
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
}