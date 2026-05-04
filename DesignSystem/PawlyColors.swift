import SwiftUI

/// Modern, sophisticated palette. Earthy but refined — avoids AI slop aesthetic.
enum PawlyColors {
    // Primary
    static let forest  = Color("BrandForest")   // Deep forest green
    static let forestLight = Color("BrandForest").opacity(0.12)

    // Accent
    static let peach   = Color("BrandPeach")    // Warm peach/amber
    static let peachLight = Color("BrandPeach").opacity(0.15)

    // Backgrounds
    static let cream   = Color("BrandCream")    // Warm off-white
    static let surface = Color("BrandSurface")  // Card surface (white-ish)

    // Borders / Dividers
    static let sand    = Color("BrandSand")     // Subtle warm border

    // Text
    static let ink     = Color("BrandInk")      // Near-black text
    static let slate   = Color("BrandSlate")    // Secondary text

    // Status
    static let alert   = Color("BrandAlert")    // Red-orange warning
    static let sage    = Color("BrandSage")     // Soft green success

    // Subtle overlay for glass effects
    static let overlayLight = Color.white.opacity(0.7)
    static let shadowColor = Color.black.opacity(0.06)

    /// Accent palette for per-pet color coding. Hex strings.
    static let petAccents: [String] = [
        "#2D5F4E", // forest green
        "#E8A87C", // warm peach
        "#8FB29A", // sage green
        "#C84A3F", // terracotta
        "#6B8CAE", // slate blue
        "#B68A6A", // clay brown
        "#9B7FB3"  // muted plum
    ]
}

extension Color {
    /// Parses "#RRGGBB" or "RRGGBB" hex strings.
    init(hex: String) {
        var h = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if h.hasPrefix("#") { h.removeFirst() }
        guard h.count == 6, let v = UInt64(h, radix: 16) else {
            self = PawlyColors.forest
            return
        }
        let r = Double((v >> 16) & 0xFF) / 255.0
        let g = Double((v >>  8) & 0xFF) / 255.0
        let b = Double(v & 0xFF) / 255.0
        self = Color(.sRGB, red: r, green: g, blue: b, opacity: 1.0)
    }
}