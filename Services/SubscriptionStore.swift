import Foundation
import SwiftUI
import Combine

/// PRD — Pet Vault subscription tier. Free users may store up to 10 documents.
/// Paid unlocks unlimited storage, OCR, expiry reminders, and travel paperwork.
final class SubscriptionStore: ObservableObject {
    static let shared = SubscriptionStore()
    static let freeDocumentLimit = 10

    @Published var isPaid: Bool {
        didSet { UserDefaults.standard.set(isPaid, forKey: key) }
    }

    private let key = "pawly.vault.isPaid"

    private init() {
        self.isPaid = UserDefaults.standard.bool(forKey: key)
    }

    /// Mock helper for previews / tests.
    func setPaid(_ value: Bool) {
        isPaid = value
    }

    var canAddDocument: Bool {
        isPaid || documentCount < Self.freeDocumentLimit
    }

    var documentCount: Int {
        // Updated by VaultHomeView via setter when documents change.
        UserDefaults.standard.integer(forKey: "pawly.vault.documentCount")
    }

    func updateDocumentCount(_ count: Int) {
        UserDefaults.standard.set(count, forKey: "pawly.vault.documentCount")
        objectWillChange.send()
    }
}
