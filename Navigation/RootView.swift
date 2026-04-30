import SwiftUI

/// Decides between Onboarding and MainTabView based on whether any active pet exists.
struct RootView: View {
    @EnvironmentObject private var petContext: PetContextStore
    @EnvironmentObject private var dataStore: DataStore
    @AppStorage("pawly.onboardingComplete") private var onboardingComplete: Bool = false

    var body: some View {
        Group {
            if !onboardingComplete || dataStore.pets.filter({ $0.statusRaw == "active" }).isEmpty {
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
    }
}

#Preview("Root — with seed") {
    RootView()
        .environmentObject(PetContextStore())
        .environmentObject(DataStore.shared)
}
