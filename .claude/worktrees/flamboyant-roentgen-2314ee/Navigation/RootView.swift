import SwiftUI

/// Decides between Auth, Loading, Onboarding and MainTabView.
/// Removes the global onboardingComplete flag; the source of truth is
/// whether the authenticated user has pets in Supabase.
struct RootView: View {
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var petContext: PetContextStore
    @EnvironmentObject private var dataStore: DataStore
    @State private var initialLoadComplete = false

    var body: some View {
        Group {
            if !authService.isAuthenticated {
                AuthView()
            } else if !initialLoadComplete || dataStore.isLoading {
                loadingView
            } else if dataStore.pets.filter({ $0.statusRaw == "active" }).isEmpty {
                OnboardingCoordinator(onComplete: {})
            } else {
                MainTabView()
                    .onAppear {
                        petContext.ensureActive(from: dataStore.pets)
                    }
                    .onChange(of: dataStore.pets) { _, newValue in
                        petContext.ensureActive(from: newValue)
                    }
            }
        }
        .background(PawlyColors.cream.ignoresSafeArea())
        .task {
            if authService.isAuthenticated {
                await loadData()
            }
        }
        .onChange(of: authService.isAuthenticated) { _, isAuth in
            if isAuth {
                Task { await loadData() }
            } else {
                dataStore.clear()
                initialLoadComplete = false
            }
        }
    }

    private func loadData() async {
        initialLoadComplete = false
        await dataStore.fetchAllData()
        initialLoadComplete = true
    }

    private var loadingView: some View {
        VStack(spacing: Spacing.m) {
            ProgressView()
                .tint(PawlyColors.forest)
                .scaleEffect(1.2)
            Text("Loading your pets...")
                .font(PawlyFont.bodyMedium)
                .foregroundStyle(PawlyColors.slate)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview("Root — with seed") {
    RootView()
        .environmentObject(AuthService.shared)
        .environmentObject(PetContextStore())
        .environmentObject(DataStore.shared)
}
