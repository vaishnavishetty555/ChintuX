import SwiftUI

/// PRD §4.1 — Earthy, considered palette. Tokens mapped to asset-catalog colors
/// that automatically adapt to light/dark mode.
enum PawlyColors {
    static let forest  = Color("BrandForest")   // Primary
    static let peach   = Color("BrandPeach")    // Accent
    static let cream   = Color("BrandCream")    // Background
    static let surface = Color("BrandSurface")  // Card surface
    static let sand    = Color("BrandSand")     // Border / divider
    static let ink     = Color("BrandInk")      // Text primary
    static let slate   = Color("BrandSlate")    // Text secondary
    static let alert   = Color("BrandAlert")    // Warning
    static let sage    = Color("BrandSage")     // Success

    /// Accent palette for per-pet color coding (PRD §6.7). Hex strings.
    static let petAccents: [String] = [
        "#2D5F4E", // forest
        "#E8A87C", // peach
        "#8FB29A", // sage
        "#C84A3F", // warm terracotta (alert tone)
        "#6B8CAE", // muted slate-blue
        "#B68A6A", // clay
        "#9B7FB3"  // muted plum
    ]
}

extension Color {
    /// Parses "#RRGGBB" or "RRGGBB" hex strings; falls back to forest on failure.
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
