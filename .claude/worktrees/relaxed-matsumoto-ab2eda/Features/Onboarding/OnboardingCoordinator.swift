import SwiftUI

/// PRD §6.1 — Max 5 screens before Home.
struct OnboardingCoordinator: View {
    enum Step: Int, CaseIterable { case welcome, basics, profile, reminders, invite }

    @EnvironmentObject private var petContext: PetContextStore
    @EnvironmentObject private var dataStore: DataStore
    @StateObject private var draft = OnboardingDraft()
    @State private var step: Step = .welcome
    @State private var isCreating = false

    var onComplete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Progress bar (skipped on welcome)
            if step != .welcome {
                ProgressBar(step: step.rawValue, total: Step.allCases.count - 1)
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .padding(.top, Spacing.m)
                    .padding(.bottom, Spacing.s)
            }

            Group {
                switch step {
                case .welcome:   WelcomeScreen(onContinue: { advance() })
                case .basics:    BasicsScreen(draft: draft, onBack: { back() }, onNext: { advance() })
                case .profile:   ProfileScreen(draft: draft, onBack: { back() }, onNext: { advance() })
                case .reminders: RemindersScreen(draft: draft, onBack: { back() }, onNext: { advance() })
                case .invite:    InviteScreen(draft: draft, onBack: { back() }, onFinish: { finish() })
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(PawlyColors.cream.ignoresSafeArea())
        .environmentObject(draft)
        .overlay {
            if isCreating {
                ProgressView("Creating pet...")
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(PawlyColors.surface))
                    .shadow(radius: 10)
            }
        }
    }

    // MARK: - Navigation

    private func advance() {
        if let next = Step(rawValue: step.rawValue + 1) {
            withAnimation(Motion.transition) { step = next }
        }
    }
    private func back() {
        if let prev = Step(rawValue: step.rawValue - 1) {
            withAnimation(Motion.transition) { step = prev }
        }
    }

    private func finish() {
        Task {
            isCreating = true
            defer { isCreating = false }
            
            // Create pet in Supabase
            let newPet = await dataStore.createPet(
                name: draft.name.trimmingCharacters(in: .whitespaces),
                species: draft.species,
                breed: draft.breed.trimmingCharacters(in: .whitespaces),
                dateOfBirth: draft.hasDateOfBirth ? draft.dateOfBirth : nil,
                sex: draft.sex,
                accentHex: PawlyColors.petAccents[0]
            )
            
            // Get the newly created pet
            if let pet = newPet {
                petContext.setActive(pet)
                
                // Create enabled reminders
                let cal = Calendar.current
                let firstDue = cal.date(bySettingHour: 9, minute: 0, second: 0, of: .now) ?? .now
                
                for t in draft.firstReminders where t.enabled {
                    await dataStore.createReminder(
                        forPetId: pet.id,
                        title: t.title,
                        type: t.type,
                        recurrence: t.recurrence,
                        firstDueAt: firstDue
                    )
                }
                
                // Request notification permission (fire-and-forget).
                Task { _ = await NotificationService.requestAuthorization() }
                
                // Only call onComplete after successful creation
                onComplete()
            } else {
                // Handle error - pet creation failed
                print("Failed to create pet")
            }
        }
    }
}

// MARK: - Progress bar

private struct ProgressBar: View {
    let step: Int
    let total: Int

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(PawlyColors.sand.opacity(0.5))
                Capsule()
                    .fill(PawlyColors.forest)
                    .frame(width: max(6, geo.size.width * CGFloat(step) / CGFloat(max(1, total))))
            }
        }
        .frame(height: 4)
        .accessibilityLabel("Onboarding progress, step \(step) of \(total)")
    }
}

#Preview("Onboarding") {
    OnboardingCoordinator(onComplete: {})
        .environmentObject(PreviewSupport.previewPetContext)
        .modelContainer(PreviewSupport.container)
}
