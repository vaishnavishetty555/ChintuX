import SwiftUI

/// Refined, restrained motion. Soft ease-out curves — no bouncy springs.
enum Motion {
    static let micro       = Animation.timingCurve(0.32, 0.72, 0.0, 1.0, duration: 0.18)
    static let softEaseOut = Animation.timingCurve(0.32, 0.72, 0.0, 1.0, duration: 0.28)
    static let transition  = Animation.timingCurve(0.32, 0.72, 0.0, 1.0, duration: 0.32)
    static let celebration = Animation.timingCurve(0.32, 0.72, 0.0, 1.0, duration: 0.48)

    /// Subtle spring for tab/icon press feedback.
    static let snap        = Animation.spring(response: 0.32, dampingFraction: 0.85)

    // MARK: - Paw Buddy Care Animations

    /// Check pop animation (for todo items)
    static let checkPop    = Animation.spring(response: 0.28, dampingFraction: 0.6)
    /// Fade in for cards appearing
    static let fadeIn      = Animation.timingCurve(0.0, 0.0, 0.2, 1.0, duration: 0.35)
    /// Slide in from right
    static let slideIn     = Animation.timingCurve(0.0, 0.0, 0.2, 1.0, duration: 0.3)
    /// Gentle bounce (for streak emoji, surprise box)
    static let bounce      = Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)
    /// Pulse for interactive elements
    static let pulse       = Animation.easeInOut(duration: 2.4).repeatForever(autoreverses: true)
    /// Wiggle for pet tap interaction
    static let wiggle      = Animation.spring(response: 0.18, dampingFraction: 0.6)
}

/// Shared environment object that controls visibility of the floating tab bar.
/// Sub-screens (chat, full-bleed UI) call `.hide()` in `onAppear` and `.show()`
/// in `onDisappear`.
@MainActor
final class TabBarVisibility: ObservableObject {
    @Published var isVisible = true
    func hide() { withAnimation(Motion.transition) { isVisible = false } }
    func show() { withAnimation(Motion.transition) { isVisible = true } }
}
