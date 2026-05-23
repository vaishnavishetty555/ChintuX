import Foundation
import SwiftUI
import Combine

/// PRD §5.2 — Per-app "which pet am I currently looking at?" state.
/// Persists last-selected pet id in UserDefaults. Used by Home and Calendar
/// to drive filtering and by the PetSwitcherCarousel to render.
final class PetContextStore: ObservableObject {
    @Published var activePetID: UUID?

    private let defaultsKey = "pawly.activePetID"

    init() {
        if let raw = UserDefaults.standard.string(forKey: defaultsKey),
           let id = UUID(uuidString: raw) {
            self.activePetID = id
        }
    }

    func setActive(_ pet: PetDTO?) {
        activePetID = pet?.id
        if let id = activePetID {
            UserDefaults.standard.set(id.uuidString, forKey: defaultsKey)
        } else {
            UserDefaults.standard.removeObject(forKey: defaultsKey)
        }
    }

    /// Convenience: ensure we have a valid active pet when the full list is known.
    func ensureActive(from pets: [PetDTO]) {
        let activeAndValid = pets.first(where: { $0.id == activePetID && $0.statusRaw == "active" })
        if activeAndValid != nil { return }
        let firstActive = pets.first(where: { $0.statusRaw == "active" }) ?? pets.first
        setActive(firstActive)
    }
}
