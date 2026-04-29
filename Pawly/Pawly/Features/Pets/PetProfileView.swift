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
                    if pet.status != .active {
                        Button { setStatus(.active) } label: { Label("Restore", systemImage: "arrow.uturn.backward") }
                    }
                } label: { Image(systemName: "ellipsis.circle").tint(PawlyColors.forest) }
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
        PawlyCard {
            VStack(alignment: .leading, spacing: Spacing.s) {
                HStack(spacing: Spacing.m) {
                    PetAvatar(pet: pet, size: 84)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(pet.name).font(PawlyFont.displayMedium).foregroundStyle(PawlyColors.ink)
                        Text("\(pet.species.displayName) • \(pet.breed.isEmpty ? "Mixed" : pet.breed)")
                            .font(PawlyFont.bodyMedium)
                            .foregroundStyle(PawlyColors.slate)
                        Text(pet.ageDescription).font(PawlyFont.caption).foregroundStyle(PawlyColors.slate)
                    }
                    Spacer()
                }
                if pet.status == .lost {
                    Text("Lost — please help")
                        .font(PawlyFont.caption)
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(Capsule().fill(PawlyColors.alert))
                        .foregroundStyle(.white)
                }
                if pet.status == .passed {
                    Text("In loving memory")
                        .font(PawlyFont.caption)
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(Capsule().fill(PawlyColors.slate.opacity(0.2)))
                        .foregroundStyle(PawlyColors.slate)
                }
            }
        }
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
            infoRow("Weight", value: pet.weightKg.map { "\($0) kg" } ?? "—")
            infoRow("Sex", value: pet.sex.displayName)
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
            }
            PawlyCard {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Conditions").font(PawlyFont.headingMedium)
                    Text(pet.ongoingConditionsText.isEmpty ? "None recorded." : pet.ongoingConditionsText)
                        .font(PawlyFont.bodyMedium)
                        .foregroundStyle(PawlyColors.slate)
                }
            }
            WeightCurveCard(pet: pet)
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
                PawlyCard {
                    Text("No logs yet. Use the + button to log meals, meds, walks.")
                        .font(PawlyFont.bodyMedium).foregroundStyle(PawlyColors.slate)
                }
            } else {
                ForEach(sorted) { log in
                    PawlyCard {
                        HStack(spacing: Spacing.m) {
                            Image(systemName: log.kind.sfSymbol).foregroundStyle(PawlyColors.forest)
                            VStack(alignment: .leading) {
                                Text("\(log.kind.displayName): \(log.detail.isEmpty ? "—" : log.detail)")
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
        PawlyCard {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Documents").font(PawlyFont.headingMedium)
                Text("Attach prescriptions, vaccine cards, and adoption papers from each reminder.")
                    .font(PawlyFont.bodyMedium).foregroundStyle(PawlyColors.slate)
            }
        }
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
        PawlyCard {
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
        }
    }
}
