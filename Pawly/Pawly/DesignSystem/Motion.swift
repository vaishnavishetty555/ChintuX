import SwiftUI

/// PRD §4.5 — Restrained motion. Default soft ease-out, no bouncy springs.
enum Motion {
    /// Custom cubic bezier (0.32, 0.72, 0, 1) — matches PRD.
    static let softEaseOut = Animation.timingCurve(0.32, 0.72, 0.0, 1.0, duration: 0.32)

    static let micro       = Animation.timingCurve(0.32, 0.72, 0.0, 1.0, duration: 0.20)
    static let transition  = Animation.timingCurve(0.32, 0.72, 0.0, 1.0, duration: 0.32)
    static let celebration = Animation.timingCurve(0.32, 0.72, 0.0, 1.0, duration: 0.48)
}
