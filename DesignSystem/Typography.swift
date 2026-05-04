import SwiftUI

/// Typography tokens using SF Pro — clean, professional iOS feel.
/// No decorative serifs. Rely on weight and size to create hierarchy.
enum PawlyFont {
    // Display — large hero text
    static let displayLarge  = Font.system(size: 34, weight: .bold,   design: .rounded)
    static let displayMedium = Font.system(size: 28, weight: .semibold, design: .rounded)

    // Heading — section titles
    static let headingLarge  = Font.system(size: 22, weight: .semibold, design: .default)
    static let headingMedium = Font.system(size: 18, weight: .semibold, design: .default)

    // Body — readable content
    static let bodyLarge     = Font.system(size: 16, weight: .regular,  design: .default)
    static let bodyMedium    = Font.system(size: 14, weight: .regular,  design: .default)

    // Caption — metadata and labels
    static let caption       = Font.system(size: 12, weight: .medium,   design: .default)
    static let captionSmall  = Font.system(size: 11, weight: .medium,   design: .default)

    // Monospaced — numbers, times, counters
    static let tabular       = Font.system(size: 16, weight: .medium,   design: .monospaced)
    static let tabularSmall  = Font.system(size: 13, weight: .medium,   design: .monospaced)
}