import SwiftUI

/// Five tabs. Center slot is the Quick Log FAB. Modern floating tab bar design
/// with glass-like surface and subtle shadow. No harsh borders.
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
            // Pad bottom to avoid content under tab bar
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 84)
            }

            // Custom floating tab bar
            PawlyTabBar(selected: $selected, onAddTap: { showingQuickLog = true })
        }
        .sheet(isPresented: $showingQuickLog) {
            QuickLogSheet()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Tab Bar

struct PawlyTabBar: View {
    @Binding var selected: MainTabView.Tab
    var onAddTap: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            tab(.home,      symbol: "house.fill",    label: "Home")
            tab(.calendar,  symbol: "calendar",      label: "Calendar")
            addButton
            tab(.discover,  symbol: "sparkles",      label: "Discover")
            tab(.pets,      symbol: "pawprint.fill", label: "Pets")
        }
        .padding(.horizontal, Spacing.xs)
        .padding(.top, Spacing.xs)
        .padding(.bottom, 20)
        .frame(height: 72)
        .background(
            .ultraThinMaterial
        )
        .overlay(
            Rectangle()
                .fill(PawlyColors.sand.opacity(0.3))
                .frame(height: 0.5),
            alignment: .top
        )
        .clipShape(RoundedRectangle(cornerRadius: Radius.button, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 4)
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private func tab(_ tab: MainTabView.Tab, symbol: String, label: String) -> some View {
        let isSelected = selected == tab
        Button {
            Haptics.light()
            withAnimation(.easeInOut(duration: 0.2)) { selected = tab }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: symbol)
                    .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? PawlyColors.forest : PawlyColors.slate)
                Text(label)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? PawlyColors.forest : PawlyColors.slate)
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var addButton: some View {
        Button {
            Haptics.medium()
            onAddTap()
        } label: {
            ZStack {
                Circle()
                    .fill(PawlyColors.forest)
                    .frame(width: 52, height: 52)
                    .shadow(color: PawlyColors.forest.opacity(0.35), radius: 10, x: 0, y: 5)
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                    .offset(y: -1)
            }
            .frame(width: 64, height: 64)
            .offset(y: -14)
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