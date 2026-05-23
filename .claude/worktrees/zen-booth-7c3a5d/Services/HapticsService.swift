import Foundation
import UIKit
import SwiftUI

/// PRD §9 — Subtle haptics on mark-done and pet-switch. Disabled when the user
/// has enabled Reduce Motion.
enum Haptics {
    static func light() {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        let g = UIImpactFeedbackGenerator(style: .light)
        g.prepare()
        g.impactOccurred()
    }
    static func medium() {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        let g = UIImpactFeedbackGenerator(style: .medium)
        g.prepare()
        g.impactOccurred()
    }
    static func success() {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        let g = UINotificationFeedbackGenerator()
        g.prepare()
        g.notificationOccurred(.success)
    }
    static func warning() {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        let g = UINotificationFeedbackGenerator()
        g.prepare()
        g.notificationOccurred(.warning)
    }
}
