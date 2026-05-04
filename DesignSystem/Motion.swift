import SwiftUI

/// Restrained motion for a polished feel. Soft ease-out curves, no bouncy springs.
enum Motion {
    static let softEaseOut = Animation.timingCurve(0.32, 0.72, 0.0, 1.0, duration: 0.32)
    static let micro       = Animation.timingCurve(0.32, 0.72, 0.0, 1.0, duration: 0.20)
    static let transition  = Animation.timingCurve(0.32, 0.72, 0.0, 1.0, duration: 0.28)
    static let celebration = Animation.timingCurve(0.32, 0.72, 0.0, 1.0, duration: 0.48)

    /// Spring-like but refined
    static let springOut = Animation.spring(response: 0.35, dampingFraction: 0.8)
}