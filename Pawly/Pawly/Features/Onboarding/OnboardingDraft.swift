import Foundation
import SwiftUI

/// Holds user input across onboarding steps. Finalized to SwiftData on completion.
@MainActor
final class OnboardingDraft: ObservableObject {
    // Step 2
    @Published var name: String = ""
    @Published var species: Species = .dog
    @Published var breed: String = ""
    @Published var dateOfBirth: Date = Calendar.current.date(byAdding: .year, value: -1, to: .now) ?? .now
    @Published var hasDateOfBirth: Bool = true
    @Published var photoData: Data?

    // Step 3
    @Published var weightKg: String = ""   // string for TextField
    @Published var sex: PetSex = .unknown
    @Published var neutered: Bool = false
    @Published var allergies: String = ""
    @Published var conditions: String = ""

    // Step 4
    struct ReminderToggle: Identifiable {
        let id = UUID()
        let type: ReminderType
        let title: String
        let recurrence: Recurrence
        var enabled: Bool
    }

    @Published var firstReminders: [ReminderToggle] = [
        .init(type: .dewormingTickFlea, title: "Monthly deworming",
              recurrence: .monthly(day: Calendar.current.component(.day, from: .now)),
              enabled: true),
        .init(type: .vaccination, title: "Annual vaccination",
              recurrence: .everyNMonths(12, day: Calendar.current.component(.day, from: .now)),
              enabled: true),
        .init(type: .weightCheck, title: "Monthly weight check",
              recurrence: .monthly(day: Calendar.current.component(.day, from: .now)),
              enabled: false)
    ]

    // Step 5 — partner invite is cosmetic per locked decisions.
    @Published var partnerName: String = ""
}
