import SwiftUI
import SwiftData

/// PRD §6.4 — Calendar tab. Month view with status dots, day bottom sheet,
/// and swipe-left to week view.
struct CalendarView: View {
    enum Mode { case month, week }

    @Query(
        filter: #Predicate<Pet> { $0.statusRaw == "active" },
        sort: [SortDescriptor(\Pet.createdAt)]
    ) private var pets: [Pet]

    @EnvironmentObject var petContext: PetContextStore
    @State private var anchor: Date = Date()        // current focused month / week
    @State private var mode: Mode = .month
    @State private var showingDaySheet: Date?
    @State private var filterPetID: UUID?           // nil = all pets

    var body: some View {
        VStack(spacing: 0) {
            header
            petFilterRow
            if mode == .month {
                MonthGrid(
                    anchor: anchor,
                    pets: filteredPets,
                    onTapDay: { day in
                        Haptics.light()
                        showingDaySheet = day
                    }
                )
                .padding(.horizontal, Spacing.screenHorizontal)
                .gesture(
                    DragGesture(minimumDistance: 40)
                        .onEnded { value in
                            if value.translation.width < -60 {
                                withAnimation(Motion.transition) { mode = .week }
                            }
                        }
                )
            } else {
                WeekTimelineView(anchor: anchor, pets: filteredPets)
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .gesture(
                        DragGesture(minimumDistance: 40)
                            .onEnded { value in
                                if value.translation.width > 60 {
                                    withAnimation(Motion.transition) { mode = .month }
                                }
                            }
                    )
            }
            adherenceRow
        }
        .background(PawlyColors.cream.ignoresSafeArea())
        .sheet(item: Binding(
            get: { showingDaySheet.map { DayID(date: $0) } },
            set: { showingDaySheet = $0?.date }
        )) { id in
            DayDetailSheet(day: id.date, pets: filteredPets)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    private var filteredPets: [Pet] {
        guard let id = filterPetID else { return pets }
        return pets.filter { $0.id == id }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: Spacing.s) {
            PetSwitcherCarousel(pets: pets)
            Spacer()
            Button {
                Haptics.light()
                withAnimation(Motion.transition) { anchor = shift(by: -1) }
            } label: { Image(systemName: "chevron.left").foregroundStyle(PawlyColors.ink) }

            Text(headerTitle).font(PawlyFont.headingMedium).foregroundStyle(PawlyColors.ink)
                .frame(minWidth: 160)

            Button {
                Haptics.light()
                withAnimation(Motion.transition) { anchor = shift(by: 1) }
            } label: { Image(systemName: "chevron.right").foregroundStyle(PawlyColors.ink) }

            Menu {
                Button("Month view") { mode = .month }
                Button("Week view")  { mode = .week }
            } label: {
                Image(systemName: "calendar").foregroundStyle(PawlyColors.forest)
            }
        }
        .padding(.horizontal, Spacing.screenHorizontal)
        .padding(.top, Spacing.m)
        .padding(.bottom, Spacing.s)
    }

    private var headerTitle: String {
        let f = DateFormatter()
        if mode == .month {
            f.dateFormat = "LLLL yyyy"
            return f.string(from: anchor)
        } else {
            let cal = Calendar.current
            let start = cal.dateInterval(of: .weekOfYear, for: anchor)?.start ?? anchor
            let end   = cal.date(byAdding: .day, value: 6, to: start) ?? anchor
            let df = DateFormatter(); df.dateFormat = "MMM d"
            return "\(df.string(from: start)) – \(df.string(from: end))"
        }
    }

    private func shift(by n: Int) -> Date {
        let cal = Calendar.current
        switch mode {
        case .month: return cal.date(byAdding: .month, value: n, to: anchor) ?? anchor
        case .week:  return cal.date(byAdding: .weekOfYear, value: n, to: anchor) ?? anchor
        }
    }

    // MARK: - Pet filter chip row

    private var petFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                chip("All", color: PawlyColors.forest, active: filterPetID == nil) {
                    filterPetID = nil
                }
                ForEach(pets) { pet in
                    chip(pet.name,
                         color: Color(hex: pet.accentHex),
                         active: filterPetID == pet.id) {
                        filterPetID = pet.id
                    }
                }
            }
            .padding(.horizontal, Spacing.screenHorizontal)
        }
        .padding(.bottom, Spacing.s)
    }

    @ViewBuilder
    private func chip(_ label: String, color: Color, active: Bool, onTap: @escaping () -> Void) -> some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Circle().fill(color).frame(width: 8, height: 8)
                Text(label).font(PawlyFont.caption)
            }
            .padding(.horizontal, Spacing.s)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(active ? color.opacity(0.15) : PawlyColors.surface)
            )
            .overlay(
                Capsule().stroke(active ? color : PawlyColors.sand, lineWidth: 1)
            )
            .foregroundStyle(PawlyColors.ink)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Adherence

    private var adherenceRow: some View {
        let cal = Calendar.current
        let start = cal.date(byAdding: .day, value: -30, to: .now) ?? .now
        let instances = filteredPets
            .flatMap(\.reminders)
            .flatMap(\.instances)
            .filter { $0.scheduledAt >= start && $0.scheduledAt <= .now }
        let completed = instances.filter { $0.status == .completed }.count
        let total = instances.count
        let pct = total == 0 ? 0 : Int(round(Double(completed) / Double(total) * 100))
        return PawlyCard {
            HStack {
                VStack(alignment: .leading) {
                    Text("30-day adherence")
                        .font(PawlyFont.caption).foregroundStyle(PawlyColors.slate)
                    Text("\(pct)%")
                        .font(PawlyFont.displayMedium)
                        .foregroundStyle(PawlyColors.ink)
                }
                Spacer()
                Text("\(completed) of \(total) done")
                    .font(PawlyFont.bodyMedium)
                    .foregroundStyle(PawlyColors.slate)
            }
        }
        .padding(.horizontal, Spacing.screenHorizontal)
        .padding(.vertical, Spacing.s)
    }
}

private struct DayID: Identifiable, Hashable {
    var date: Date
    var id: Date { date }
}

#Preview("Calendar") {
    CalendarView()
        .environmentObject(PreviewSupport.previewPetContext)
        .modelContainer(PreviewSupport.container)
}
