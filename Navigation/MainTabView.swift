import SwiftUI
import SwiftData

/// PRD §5.1 — Five tabs. The middle slot is a center "Add" FAB that presents
/// the Quick Log sheet. SwiftUI's TabView doesn't natively support a FAB in
/// the middle so we render a custom bottom bar overlay.
struct MainTabView: View {
    enum Tab: Hashable { case home, calendar, discover, pets }

    @State private var selected: Tab = .home
    @State private var showingQuickLog = false

    var body: some View {
        ZStack(alignment: .bottom) {
            // Content area
            Group {
                switch selected {
                case .home:     HomeView()
                case .calendar: NavigationStack { CalendarView() }
                case .discover: DiscoverView()
                case .pets:     PetsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(PawlyColors.cream.ignoresSafeArea())
            // Pad bottom so content doesn't hide behind the custom tab bar.
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 76)
            }

            // Custom tab bar with center FAB.
            PawlyTabBar(
                selected: $selected,
                onAddTap: { showingQuickLog = true }
            )
        }
        .sheet(isPresented: $showingQuickLog) {
            QuickLogSheet()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
}

struct PawlyTabBar: View {
    @Binding var selected: MainTabView.Tab
    var onAddTap: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            tab(.home,     symbol: "house.fill",     label: "Home")
            tab(.calendar, symbol: "calendar",       label: "Calendar")
            addButton
            tab(.discover, symbol: "sparkles",       label: "Discover")
            tab(.pets,     symbol: "pawprint.fill",  label: "Pets")
        }
        .padding(.horizontal, Spacing.s)
        .padding(.top, Spacing.xs)
        .padding(.bottom, Spacing.xs)
        .frame(height: 76)
        .background(
            PawlyColors.surface
                .overlay(
                    Rectangle()
                        .fill(PawlyColors.sand)
                        .frame(height: 0.5),
                    alignment: .top
                )
                .ignoresSafeArea(edges: .bottom)
        )
    }

    @ViewBuilder
    private func tab(_ tab: MainTabView.Tab, symbol: String, label: String) -> some View {
        Button {
            Haptics.light()
            withAnimation(Motion.micro) { selected = tab }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: symbol)
                    .font(.system(size: 20, weight: selected == tab ? .semibold : .regular))
                Text(label).font(PawlyFont.captionSmall)
            }
            .frame(maxWidth: .infinity, minHeight: Spacing.tapTargetMin)
            .foregroundStyle(selected == tab ? PawlyColors.forest : PawlyColors.slate)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityAddTraits(selected == tab ? .isSelected : [])
    }

    private var addButton: some View {
        Button {
            Haptics.medium()
            onAddTap()
        } label: {
            ZStack {
                Circle().fill(PawlyColors.forest)
                    .frame(width: 56, height: 56)
                    .shadow(color: PawlyColors.forest.opacity(0.25), radius: 10, x: 0, y: 4)
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color.white)
            }
            .frame(width: 64, height: 64)
            .offset(y: -12) // lifts above the bar
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add log entry")
    }
}

#Preview("Main") {
    MainTabView()
        .environmentObject(PreviewSupport.previewPetContext)
        .modelContainer(PreviewSupport.container)
}
