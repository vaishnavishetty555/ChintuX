import SwiftUI

/// Floating tab bar. Glass effect with center add button.
/// Paw Buddy Care warm pastel design.
struct MainTabView: View {
    enum Tab: Hashable { case home, track, vault, discover }

    @State private var selected: Tab = .home
    @StateObject private var tabBarVisibility = TabBarVisibility()

    var body: some View {
        ZStack {
            PawlyColors.pastelBg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Sticky app header
                PBCAppHeader()

                // Content area
                Group {
                    switch selected {
                    case .home:     NavigationStack { HomeView() }
                    case .track:    NavigationStack { TrackDashboardView() }
                    case .vault:    NavigationStack { VaultHomeView() }
                    case .discover: NavigationStack { DiscoverView() }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Floating tab bar at bottom
                if tabBarVisibility.isVisible {
                    PBCTabBar(selected: $selected)
                        .padding(.bottom, 8)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .ignoresSafeArea(.keyboard)
        }
        .environmentObject(tabBarVisibility)
    }
}

// MARK: - Paw Buddy Care Tab Bar

struct PBCTabBar: View {
    @Binding var selected: MainTabView.Tab

    private var primaryColor: Color { PawlyColors.peachAccent }

    var body: some View {
        HStack(spacing: 0) {
            tab(.home,     symbol: "house",        label: "Today")
            tab(.track,    symbol: "heart.fill",   label: "Track")
            tab(.vault,    symbol: "lock.doc",     label: "Vault")
            tab(.discover, symbol: "stethoscope",  label: "Ask")
        }
        .padding(.horizontal, 6)
        .frame(height: 60)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color.white.opacity(0.4))
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.black.opacity(0.05), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 20, x: 0, y: 10)
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    @ViewBuilder
    private func tab(_ tab: MainTabView.Tab, symbol: String, label: String) -> some View {
        let isSelected = selected == tab
        Button {
            Haptics.light()
            withAnimation(Motion.snap) { selected = tab }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: isSelected ? symbol : symbol)
                    .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? primaryColor : PawlyColors.inkSoft.opacity(0.5))
                    .symbolRenderingMode(.hierarchical)
                Text(label)
                    .font(.system(size: 9.5, weight: isSelected ? .bold : .medium))
                    .foregroundStyle(isSelected ? primaryColor : PawlyColors.inkSoft.opacity(0.5))
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

}

#Preview("Main") {
    MainTabView()
        .environmentObject(PreviewSupport.previewPetContext)
        .modelContainer(PreviewSupport.container)
}
