import SwiftUI

/// PRD §4.2 — Typography. Currently renders with SF Pro via `.system(...)`.
/// To wire Fraunces + Inter later, replace the `.system(...)` calls with
/// `.custom("Fraunces", size:)` / `.custom("Inter", size:)` — no call sites change.
enum PawlyFont {
    // Display (Fraunces stand-in — serif for warmth)
    static let displayLarge  = Font.system(size: 32, weight: .semibold, design: .serif)
    static let displayMedium = Font.system(size: 28, weight: .medium,   design: .serif)

    // Heading (Inter stand-in)
    static let headingLarge  = Font.system(size: 22, weight: .semibold, design: .default)
    static let headingMedium = Font.system(size: 18, weight: .semibold, design: .default)

    // Body
    static let bodyLarge     = Font.system(size: 16, weight: .regular,  design: .default)
    static let bodyMedium    = Font.system(size: 14, weight: .regular,  design: .default)

    // Caption
    static let caption       = Font.system(size: 12, weight: .medium,   design: .default)
    static let captionSmall  = Font.system(size: 11, weight: .medium,   design: .default)

    // Tabular numerals for counters & calendar
    static let tabular       = Font.system(size: 16, weight: .medium,   design: .monospaced)
    static let tabularSmall  = Font.system(size: 13, weight: .medium,   design: .monospaced)
}
