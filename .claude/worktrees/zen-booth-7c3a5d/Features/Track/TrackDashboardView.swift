import SwiftUI
import SwiftData

/// Track Dashboard — pet health tracking with 3 focused tabs.
/// Health (meds + food), Docs (vaccines + records), Vet (visits).
struct TrackDashboardView: View {
    @EnvironmentObject var petContext: PetContextStore
    @EnvironmentObject var dataStore: DataStore

    @State private var selectedTab: TrackTab = .health

    enum TrackTab: String, CaseIterable {
        case health = "Health"
        case vet    = "Vet"

        var icon: String {
            switch self {
            case .health: return "heart.fill"
            case .vet:    return "stethoscope"
            }
        }
    }

    var activePet: PetDTO? {
        dataStore.pets.first { $0.id == petContext.activePetID } ?? dataStore.pets.first
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("TRACK")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(PawlyColors.inkSoft)
                            .tracking(1)
                        Text("\(activePet?.name ?? "Pet")'s health")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(PawlyColors.ink)
                    }
                    Spacer()
                    if let pet = activePet {
                        PetAvatarDTO(pet: pet, size: 40)
                    }
                }
                .padding(.horizontal, Spacing.screenHorizontal)
                .padding(.top, Spacing.m)
                .padding(.bottom, Spacing.m)

                // Segmented control
                TrackSegmentedControl(selection: $selectedTab)
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .padding(.bottom, Spacing.m)

                // Tab content
                switch selectedTab {
                case .health: HealthTabContent(pet: activePet)
                case .vet:    VetTabContent(pet: activePet)
                }

                Spacer(minLength: Spacing.tabBarBottomSafe)
            }
        }
        .background(PawlyColors.pastelBg.ignoresSafeArea())
        .scrollIndicators(.hidden)
    }
}

// MARK: - Segmented Control

struct TrackSegmentedControl: View {
    @Binding var selection: TrackDashboardView.TrackTab

    var body: some View {
        HStack(spacing: 4) {
            ForEach(TrackDashboardView.TrackTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(Motion.snap) { selection = tab }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 11, weight: .medium))
                        Text(tab.rawValue)
                            .font(.system(size: 12, weight: .bold))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .fill(selection == tab ? Color.white : .clear)
                    )
                    .foregroundStyle(selection == tab ? PawlyColors.ink : PawlyColors.inkSoft)
                    .shadow(color: selection == tab ? .black.opacity(0.05) : .clear, radius: 4, x: 0, y: 2)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.black.opacity(0.05))
        )
    }
}

// MARK: - Health Tab (Meds + Food)

struct HealthTabContent: View {
    let pet: PetDTO?
    @EnvironmentObject var dataStore: DataStore
    @State private var showingAddReminder = false
    @State private var editingReminder: ReminderDTO?

    var body: some View {
        VStack(spacing: 0) {
            // ── Add reminder button ──
            Button {
                if pet != nil { showingAddReminder = true }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Add reminder")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(PawlyColors.peachAccent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(
                    RoundedRectangle(cornerRadius: Radius.cardLg, style: .continuous)
                        .stroke(PawlyColors.peachAccent, style: StrokeStyle(lineWidth: 1.5, dash: [5, 3]))
                )
            }
            .buttonStyle(.plain)
            .disabled(pet == nil)
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.top, Spacing.m)
            .padding(.bottom, Spacing.s)

            // ── Today's care ──
            if let pet {
                TodayChecklistSection(pet: pet)
                    .padding(.top, Spacing.s)
            }

            // ── Upcoming this week ──
            if let pet {
                UpcomingWeekSection(pet: pet) { reminder in
                    editingReminder = reminder
                }
                .padding(.top, Spacing.xl)
                .padding(.bottom, Spacing.m)
            }
        }
        .sheet(isPresented: $showingAddReminder) {
            if let pet {
                ReminderEditViewDTO(pet: pet, existing: nil)
            }
        }
        .sheet(item: $editingReminder) { reminder in
            if let pet {
                ReminderEditViewDTO(pet: pet, existing: reminder)
            }
        }
    }

}

struct TrackSectionHeader: View {
    let title: String
    let icon: String
    let iconColor: Color
    var topPadding: CGFloat = Spacing.m

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(iconColor)
            Text(title)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(PawlyColors.ink)
            Spacer()
        }
        .padding(.horizontal, Spacing.screenHorizontal)
        .padding(.top, topPadding)
        .padding(.bottom, Spacing.s)
    }
}

struct DewormChip: View {
    let name: String
    let last: String
    let next: String
    let status: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(PawlyColors.ink)
            Text("Last: \(last)")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(PawlyColors.inkSoft)
            Text("Next: \(next)")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(PawlyColors.wellnessNutrition)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
        )
    }
}

struct MedReminderCard: View {
    let reminder: ReminderDTO
    let todayInstance: ReminderInstanceDTO?
    let nextFutureInstance: ReminderInstanceDTO?
    let onToggle: (ReminderInstanceDTO) -> Void
    let onEdit: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Left: icon + title (tap → edit)
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(PawlyColors.peachAccent.opacity(0.15)).frame(width: 44, height: 44)
                    Image(systemName: ReminderType(rawValue: reminder.typeRaw)?.sfSymbol ?? "pills.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(PawlyColors.peachAccent)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(reminder.title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(PawlyColors.ink)
                        .lineLimit(1)
                    Text(subtitleText)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(PawlyColors.inkSoft)
                        .lineLimit(1)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { onEdit() }

            Spacer(minLength: 8)

            // Right: contextual action
            rightAction
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: Radius.cardLg, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)
        )
    }

    @ViewBuilder
    private var rightAction: some View {
        if let instance = todayInstance {
            if instance.statusRaw == "completed" {
                Button { onToggle(instance) } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                        Text("Taken")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(PawlyColors.wellnessNutrition))
                }
                .buttonStyle(.plain)
            } else {
                Button { onToggle(instance) } label: {
                    Text("Mark taken")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(PawlyColors.peachAccent))
                }
                .buttonStyle(.plain)
            }
        } else if let next = nextFutureInstance {
            VStack(alignment: .trailing, spacing: 1) {
                Text("Next")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(PawlyColors.inkSoft)
                    .tracking(0.4)
                Text(nextLabel(for: next.scheduledAt))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(PawlyColors.ink)
            }
        } else {
            Text("No upcoming")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(PawlyColors.inkSoft)
        }
    }

    private var subtitleText: String {
        var parts: [String] = []
        if let dosage = reminder.dosage, !dosage.isEmpty {
            parts.append(dosage)
        }
        if let r = Recurrence(rawString: reminder.recurrenceRaw) {
            parts.append(r.displayDescription)
        }
        return parts.isEmpty ? reminder.typeRaw : parts.joined(separator: " · ")
    }

    private func nextLabel(for date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInTomorrow(date) {
            let f = DateFormatter(); f.dateFormat = "h:mm a"
            return "Tomorrow \(f.string(from: date))"
        }
        let days = cal.dateComponents([.day], from: Date().startOfDay, to: date.startOfDay).day ?? 0
        if days < 7 {
            let f = DateFormatter(); f.dateFormat = "EEE h:mm a"
            return f.string(from: date)
        }
        let f = DateFormatter(); f.dateFormat = "MMM d"
        return f.string(from: date)
    }
}

struct NutritionStatCardExpanded: View {
    let icon: String
    let iconColor: Color
    let label: String
    let count: Int
    let targetLabel: String
    let progress: Double
    let progressColor: Color
    let bgColor: Color
    let onQuickLog: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                ZStack {
                    Circle().fill(Color.white).frame(width: 30, height: 30)
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(iconColor)
                }
                Text(label.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(PawlyColors.inkSoft)
                    .tracking(0.6)
                Spacer()
                Button { onQuickLog() } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(iconColor)
                        .frame(width: 24, height: 24)
                        .background(iconColor.opacity(0.12))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(count == 0 ? "—" : "\(count)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(PawlyColors.ink)
                    .contentTransition(.numericText())
                Text(targetLabel)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(PawlyColors.inkSoft)
            }
            if progress > 0 {
                PBCProgressBar(value: progress * 100, color: progressColor, background: Color.white.opacity(0.7))
            } else {
                Text("Log your first \(label.lowercased()) entry")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(PawlyColors.inkSoft.opacity(0.6))
                    .padding(.top, 2)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Radius.cardLg, style: .continuous)
                .fill(bgColor)
        )
    }
}

struct MealLogRow: View {
    let entry: LogEntryDTO

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: entry.at)
    }

    var body: some View {
        HStack(spacing: 0) {
            Text(timeString)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(PawlyColors.inkSoft)
                .frame(width: 60, alignment: .trailing)
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(PawlyColors.wellnessNutrition)
                        .frame(width: 12, height: 12)
                }
                .padding(.vertical, 4)
            }
            .frame(width: 14)
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(entry.detail.isEmpty ? "Meal" : entry.detail)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(PawlyColors.ink)
                    Spacer()
                    if let val = entry.numericValue {
                        Text("\(Int(val))g")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(PawlyColors.wellnessNutrition)
                    }
                }
                Text(entry.at.formatted(.dateTime.month().day()))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(PawlyColors.inkSoft)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: Radius.cardLg, style: .continuous).fill(Color.white))
        }
    }
}

// MARK: - Docs Tab (Vaccines + Records)

struct DocsTabContent: View {
    let pet: PetDTO?

    @Query(sort: [SortDescriptor(\PetDocument.createdAt, order: .reverse)])
    private var allDocuments: [PetDocument]

    private var relevantDocs: [PetDocument] {
        guard let petId = pet?.id else { return allDocuments }
        return allDocuments.filter { $0.pet?.id == petId }
    }

    private var vaccinationDocs: [PetDocument] {
        relevantDocs.filter { $0.documentType == .vaccinationCertificate }
    }

    private var upcomingVaccineDocs: [PetDocument] {
        relevantDocs.filter { $0.documentType == .vaccinationCertificate && $0.isExpiringSoon }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Immunity header
            TrackSectionHeader(title: "Vaccinations", icon: "shield.fill", iconColor: PawlyColors.wellnessHydration)

            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(Color.white).frame(width: 56, height: 56)
                    Image(systemName: "shield.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(PawlyColors.wellnessHydration)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("IMMUNITY STATUS")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(PawlyColors.inkSoft)
                        .tracking(0.8)
                    if vaccinationDocs.isEmpty {
                        Text("No vaccination records")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(PawlyColors.ink)
                    } else {
                        Text("\(vaccinationDocs.count) vaccination\(vaccinationDocs.count == 1 ? "" : "s") on file")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(PawlyColors.ink)
                    }
                }
                Spacer()
            }
            .padding(Spacing.m)
            .background(
                RoundedRectangle(cornerRadius: Radius.cardLg, style: .continuous)
                    .fill(LinearGradient(colors: [PawlyColors.CardTone.sky.bg, PawlyColors.pastelSurface2], startPoint: .topLeading, endPoint: .bottomTrailing))
            )
            .padding(.horizontal, Spacing.screenHorizontal)

            // Vaccine cards
            if vaccinationDocs.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "syringe.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(PawlyColors.inkSoft.opacity(0.3))
                    Text("No vaccination records")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(PawlyColors.inkSoft)
                    Text("Upload vaccination certificates in the Vault tab")
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
                .padding(.top, Spacing.m)
            } else {
                VStack(spacing: 10) {
                    ForEach(vaccinationDocs) { doc in
                        VaccineDocRow(doc: doc)
                    }
                }
                .padding(.horizontal, Spacing.screenHorizontal)
                .padding(.top, Spacing.m)
            }

            // Other documents
            TrackSectionHeader(title: "Records", icon: "doc.text.fill", iconColor: PawlyColors.peachAccent)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(DocumentType.allCases) { docType in
                    let count = relevantDocs.filter { $0.documentType == docType }.count
                    let cardTone = PawlyColors.CardTone(rawValue: docTypeOrder(docType)) ?? .peach
                    VStack(alignment: .leading, spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.white)
                                .frame(width: 36, height: 36)
                            Image(systemName: docType.sfSymbol)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(cardTone.tint)
                        }
                        Text(docType.displayName)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(PawlyColors.ink)
                            .lineLimit(1)
                        Text("\(count) file\(count == 1 ? "" : "s")")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(PawlyColors.inkSoft)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: Radius.cardLg, style: .continuous)
                            .fill(cardTone.bg)
                            .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
                    )
                }
            }
            .padding(.horizontal, Spacing.screenHorizontal)
        }
    }

    private func docTypeOrder(_ type: DocumentType) -> Int {
        switch type {
        case .vaccinationCertificate: return 1
        case .microchipDetails: return 6
        case .vetBill: return 3
        case .insurance: return 2
        case .breederPapers: return 5
        case .petPassport: return 4
        case .license: return 0
        case .other: return 7
        }
    }
}

struct VaccineDocRow: View {
    let doc: PetDocument

    private var statusText: String {
        if let days = doc.daysUntilExpiry {
            if days < 0 { return "Expired" }
            if days <= 30 { return "Due soon" }
            return "Active"
        }
        return "Active"
    }

    private var statusColor: Color {
        if let days = doc.daysUntilExpiry {
            if days < 0 { return Color(hex: "#D32F2F") }
            if days <= 30 { return PawlyColors.peachAccentDeep }
            return PawlyColors.wellnessNutrition
        }
        return PawlyColors.wellnessNutrition
    }

    private var cardTone: PawlyColors.CardTone {
        if let days = doc.daysUntilExpiry {
            if days < 0 { return .rose }
            if days <= 30 { return .peach }
            return .sage
        }
        return .sage
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(cardTone.bg).frame(width: 44, height: 44)
                Image(systemName: "syringe.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(cardTone.tint)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(doc.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(PawlyColors.ink)
                    .lineLimit(1)
                Text(doc.createdAt.formatted(.dateTime.month().day().year()))
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundStyle(PawlyColors.inkSoft)
                    .lineLimit(1)
            }
            Spacer()
            PBChip(text: statusText, tone: cardTone.bg, textColor: statusColor)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: Radius.cardLg, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)
        )
    }
}

// MARK: - Vet Tab

struct VetTabContent: View {
    let pet: PetDTO?
    @EnvironmentObject var dataStore: DataStore
    @State private var showingAddVet = false
    @State private var editingReminder: ReminderDTO?
    @State private var markDoneReminder: ReminderDTO?   // future visit awaiting confirmation
    @State private var showingMarkDoneConfirm = false
    @State private var selectedHistoryItem: (instance: ReminderInstanceDTO, title: String, notes: String)?

    private var vetReminders: [ReminderDTO] {
        guard let petId = pet?.id else { return [] }
        return dataStore.reminders.filter {
            $0.petId == petId && ReminderType(rawValue: $0.typeRaw) == .vetCheckup
        }
    }

    /// All active vet reminders that have no completed instance yet — includes overdue ones.
    private var upcomingVetVisits: [ReminderDTO] {
        let completedIds = Set(
            dataStore.reminderInstances
                .filter { $0.statusRaw == "completed" }
                .compactMap { $0.reminderId }
        )
        let now = Date()
        return vetReminders
            .filter { $0.isActive && !completedIds.contains($0.id) }
            .sorted { a, b in
                let aFuture = a.firstDueAt >= now
                let bFuture = b.firstDueAt >= now
                if aFuture != bFuture { return aFuture } // future visits first
                return a.firstDueAt < b.firstDueAt
            }
    }

    /// Completed vet reminder instances paired with their parent reminder title and notes.
    private var pastVetVisits: [(instance: ReminderInstanceDTO, title: String, notes: String)] {
        let vetReminderIds = Set(vetReminders.map(\.id))
        return dataStore.reminderInstances
            .filter { instance in
                guard let rid = instance.reminderId else { return false }
                return vetReminderIds.contains(rid) && instance.statusRaw == "completed"
            }
            .compactMap { instance -> (ReminderInstanceDTO, String, String)? in
                guard let reminder = vetReminders.first(where: { $0.id == instance.reminderId }) else { return nil }
                return (instance, reminder.title, reminder.notes)
            }
            .sorted { $0.0.completedAt ?? $0.0.scheduledAt > $1.0.completedAt ?? $1.0.scheduledAt }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Schedule vet visit — always at the top
            Button {
                if pet != nil { showingAddVet = true }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                    Text("Schedule vet visit")
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundStyle(PawlyColors.peachAccent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: Radius.cardLg, style: .continuous)
                        .stroke(PawlyColors.peachAccent, style: StrokeStyle(lineWidth: 1.5, dash: [5, 3]))
                )
            }
            .buttonStyle(.plain)
            .disabled(pet == nil)
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.bottom, Spacing.m)

            // Upcoming visit cards — all of them
            if upcomingVetVisits.isEmpty {
                Button {
                    if pet != nil { showingAddVet = true }
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "stethoscope")
                            .font(.system(size: 24))
                            .foregroundStyle(PawlyColors.lavender.opacity(0.7))
                        Text("No upcoming visits")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(PawlyColors.ink)
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill").font(.system(size: 14))
                            Text("Schedule vet visit")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(PawlyColors.peachAccent))
                        .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .background(
                        RoundedRectangle(cornerRadius: Radius.cardLg, style: .continuous)
                            .fill(LinearGradient(colors: [PawlyColors.CardTone.lavender.bg, PawlyColors.pastelSurface2], startPoint: .topLeading, endPoint: .bottomTrailing))
                    )
                }
                .buttonStyle(.plain)
                .disabled(pet == nil)
                .padding(.horizontal, Spacing.screenHorizontal)
            } else {
                VStack(spacing: 10) {
                    ForEach(Array(upcomingVetVisits.enumerated()), id: \.element.id) { index, visit in
                        let isOverdue = visit.firstDueAt < Date()
                        VStack(alignment: .leading, spacing: 10) {
                            // Header label
                            HStack(spacing: 6) {
                                if isOverdue {
                                    Text("OVERDUE")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(PawlyColors.alert)
                                        .tracking(0.8)
                                } else {
                                    Text(index == 0 ? "NEXT APPOINTMENT" : "UPCOMING")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(PawlyColors.inkSoft)
                                        .tracking(0.8)
                                }
                            }

                            // Title + date
                            VStack(alignment: .leading, spacing: 2) {
                                Text(visit.title)
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundStyle(PawlyColors.ink)
                                Text(visit.firstDueAt.formatted(.dateTime.month().day().year().hour().minute()))
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(isOverdue ? PawlyColors.alert : PawlyColors.inkSoft)
                            }

                            // Action buttons
                            HStack(spacing: 8) {
                                // Mark Done
                                Button {
                                    if isOverdue {
                                        // Past visit — mark directly
                                        Task { await dataStore.markReminderDone(reminderId: visit.id, completedAt: .now) }
                                    } else {
                                        // Future visit — ask confirmation
                                        markDoneReminder = visit
                                        showingMarkDoneConfirm = true
                                    }
                                } label: {
                                    HStack(spacing: 5) {
                                        Image(systemName: "checkmark.circle.fill").font(.system(size: 13))
                                        Text("Mark done")
                                            .font(.system(size: 12, weight: .bold))
                                    }
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(Capsule().fill(PawlyColors.forest))
                                }
                                .buttonStyle(.plain)

                                // Reschedule
                                Button {
                                    editingReminder = visit
                                } label: {
                                    Text("Reschedule")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(PawlyColors.peachAccent)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(Capsule().fill(PawlyColors.peachAccent.opacity(0.12)))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(Spacing.m)
                        .background(
                            RoundedRectangle(cornerRadius: Radius.cardLg, style: .continuous)
                                .fill(LinearGradient(
                                    colors: isOverdue
                                        ? [PawlyColors.alert.opacity(0.06), PawlyColors.pastelSurface2]
                                        : [PawlyColors.CardTone.lavender.bg, PawlyColors.pastelSurface2],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: Radius.cardLg, style: .continuous)
                                .stroke(isOverdue ? PawlyColors.alert.opacity(0.25) : Color.clear, lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, Spacing.screenHorizontal)
            }

            // Visit history
            TrackSectionHeader(title: "Visit history", icon: "clock.fill", iconColor: PawlyColors.lavender, topPadding: Spacing.m)

            if pastVetVisits.isEmpty {
                Text("No completed visits yet. Mark a scheduled visit as done to see it here.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(PawlyColors.inkSoft)
                    .padding(.horizontal, Spacing.screenHorizontal)
            } else {
                VStack(spacing: 10) {
                    ForEach(pastVetVisits, id: \.instance.id) { item in
                        Button {
                            selectedHistoryItem = item
                        } label: {
                            VetLogRow(title: item.title, date: item.instance.completedAt ?? item.instance.scheduledAt, hasNotes: !item.notes.isEmpty)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Spacing.screenHorizontal)
            }
        }
        .sheet(isPresented: $showingAddVet) {
            if let pet {
                ReminderEditViewDTO(pet: pet, existing: nil, defaultType: .vetCheckup)
            }
        }
        .sheet(item: $editingReminder) { reminder in
            if let pet {
                ReminderEditViewDTO(pet: pet, existing: reminder)
            }
        }
        .sheet(isPresented: Binding(
            get: { selectedHistoryItem != nil },
            set: { if !$0 { selectedHistoryItem = nil } }
        )) {
            if let item = selectedHistoryItem {
                VetVisitDetailSheet(title: item.title, date: item.instance.completedAt ?? item.instance.scheduledAt, notes: item.notes)
            }
        }
        .alert(
            "Mark visit as done today?",
            isPresented: $showingMarkDoneConfirm,
            presenting: markDoneReminder
        ) { reminder in
            Button("Mark done") {
                Task { await dataStore.markReminderDone(reminderId: reminder.id, completedAt: .now) }
            }
            Button("Cancel", role: .cancel) {}
        } message: { reminder in
            Text("\"\(reminder.title)\" is scheduled for \(reminder.firstDueAt.formatted(.dateTime.month().day())). Today (\(Date.now.formatted(.dateTime.month().day()))) will be recorded as the completion date.")
        }
    }
}

struct VetLogRow: View {
    let title: String
    let date: Date
    var hasNotes: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(PawlyColors.lavender.opacity(0.15)).frame(width: 36, height: 36)
                Image(systemName: "stethoscope")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(PawlyColors.lavender)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(PawlyColors.ink)
                    .lineLimit(1)
                if hasNotes {
                    HStack(spacing: 4) {
                        Image(systemName: "note.text")
                            .font(.system(size: 10))
                        Text("Has notes")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(PawlyColors.lavender)
                }
            }
            Spacer()
            HStack(spacing: 6) {
                Text(date.formatted(.dateTime.month().day().year()))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(PawlyColors.inkSoft)
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(PawlyColors.inkSoft.opacity(0.5))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: Radius.cardLg, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)
        )
    }
}

// MARK: - Vet Visit Detail Sheet

struct VetVisitDetailSheet: View {
    let title: String
    let date: Date
    let notes: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.m) {
                    // Header card
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(PawlyColors.lavender.opacity(0.15))
                                    .frame(width: 48, height: 48)
                                Image(systemName: "stethoscope")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundStyle(PawlyColors.lavender)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(title)
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundStyle(PawlyColors.ink)
                                Text("Completed \(date.formatted(.dateTime.month(.wide).day().year()))")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(PawlyColors.inkSoft)
                            }
                        }
                    }
                    .padding(Spacing.m)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: Radius.cardLg, style: .continuous)
                            .fill(LinearGradient(colors: [PawlyColors.CardTone.lavender.bg, PawlyColors.pastelSurface2], startPoint: .topLeading, endPoint: .bottomTrailing))
                    )

                    // Notes section
                    if notes.isEmpty {
                        HStack(spacing: 10) {
                            Image(systemName: "note.text")
                                .foregroundStyle(PawlyColors.inkSoft.opacity(0.4))
                            Text("No notes for this visit.")
                                .font(.system(size: 14))
                                .foregroundStyle(PawlyColors.inkSoft)
                        }
                        .padding(Spacing.m)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: Radius.cardLg, style: .continuous)
                                .fill(PawlyColors.surface)
                        )
                    } else {
                        VStack(alignment: .leading, spacing: Spacing.s) {
                            Label("Notes", systemImage: "note.text")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(PawlyColors.lavender)
                            Text(notes)
                                .font(.system(size: 15))
                                .foregroundStyle(PawlyColors.ink)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(Spacing.m)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: Radius.cardLg, style: .continuous)
                                .fill(PawlyColors.surface)
                        )
                    }
                }
                .padding(.horizontal, Spacing.screenHorizontal)
                .padding(.vertical, Spacing.m)
            }
            .background(PawlyColors.cream.ignoresSafeArea())
            .navigationTitle("Vet Visit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Track") {
    NavigationStack { TrackDashboardView() }
        .environmentObject(PetContextStore())
        .environmentObject(DataStore.shared)
}
