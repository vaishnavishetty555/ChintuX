import SwiftUI
import SwiftData

/// Decides between Onboarding and MainTabView based on whether any active pet exists.
struct RootView: View {
    @Query(
        filter: #Predicate<Pet> { $0.statusRaw == "active" },
        sort: [SortDescriptor(\Pet.createdAt)]
    ) private var activePets: [Pet]

    @EnvironmentObject private var petContext: PetContextStore
    @AppStorage("pawly.onboardingComplete") private var onboardingComplete: Bool = false

    var body: some View {
        Group {
            if !onboardingComplete || activePets.isEmpty {
                OnboardingCoordinator(onComplete: {
                    onboardingComplete = true
                })
            } else {
                MainTabView()
                    .onAppear { petContext.ensureActive(from: activePets) }
                    .onChange(of: activePets) { _, newValue in
                        petContext.ensureActive(from: newValue)
                    }
            }
        }
        .background(PawlyColors.cream.ignoresSafeArea())
    }
}

#Preview("Root — with seed") {
    RootView()
        .environmentObject(PreviewSupport.previewPetContext)
        .modelContainer(PreviewSupport.container)
}
