import SwiftUI
import SwiftData

/// PRD §6.1 — Max 5 screens before Home.
struct OnboardingCoordinator: View {
    enum Step: Int, CaseIterable { case welcome, basics, profile, reminders, invite }

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var petContext: PetContextStore
    @StateObject private var draft = OnboardingDraft()
    @State private var step: Step = .welcome

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
        let pet = Pet(
            name: draft.name.trimmingCharacters(in: .whitespaces),
            species: draft.species,
            breed: draft.breed.trimmingCharacters(in: .whitespaces),
            dateOfBirth: draft.hasDateOfBirth ? draft.dateOfBirth : nil,
            weightKg: Double(draft.weightKg),
            sex: draft.sex,
            neutered: draft.neutered,
            allergiesText: draft.allergies,
            ongoingConditionsText: draft.conditions,
            accentHex: PawlyColors.petAccents[0],
            photoData: draft.photoData
        )
        modelContext.insert(pet)

        // Create enabled reminders
        let cal = Calendar.current
        let firstDue = cal.date(bySettingHour: 9, minute: 0, second: 0, of: .now) ?? .now
        for t in draft.firstReminders where t.enabled {
            let rem = Reminder(
                pet: pet,
                title: t.title,
                type: t.type,
                recurrence: t.recurrence,
                firstDueAt: firstDue
            )
            modelContext.insert(rem)

            // Generate instances for the next 120 days
            let end = cal.date(byAdding: .day, value: 120, to: .now) ?? .now
            let dates = RecurrenceEngine.occurrences(
                recurrence: rem.recurrence,
                firstDueAt: rem.firstDueAt,
                in: Date().startOfDay..<end
            )
            for d in dates {
                modelContext.insert(ReminderInstance(reminder: rem, scheduledAt: d))
            }
        }

        do {
            try modelContext.save()
        } catch {
            // For V1 we simply log — user sees a generic retry in Home if this fails.
            print("Onboarding save failed: \(error)")
        }

        petContext.setActive(pet)

        // Request notification permission (fire-and-forget).
        Task { _ = await NotificationService.requestAuthorization() }

        onComplete()
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
