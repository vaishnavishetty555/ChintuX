import SwiftUI

/// Decides between Auth, Onboarding and MainTabView based on authentication
/// and whether any active pet exists.
struct RootView: View {
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var petContext: PetContextStore
    @EnvironmentObject private var dataStore: DataStore
    @AppStorage("pawly.onboardingComplete") private var onboardingComplete: Bool = false

    var body: some View {
        Group {
            if !authService.isAuthenticated {
                AuthView()
            } else if !onboardingComplete || dataStore.pets.filter({ $0.statusRaw == "active" }).isEmpty {
                OnboardingCoordinator(onComplete: {
                    onboardingComplete = true
                })
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
            // Fetch data once auth is confirmed
            if authService.isAuthenticated {
                await dataStore.fetchAllData()
            }
        }
        .onChange(of: authService.isAuthenticated) { _, isAuth in
            if isAuth {
                Task { await dataStore.fetchAllData() }
            } else {
                dataStore.clear()
                onboardingComplete = false
            }
        }
    }
}

#Preview("Root — with seed") {
    RootView()
        .environmentObject(AuthService.shared)
        .environmentObject(PetContextStore())
        .environmentObject(DataStore.shared)
}
