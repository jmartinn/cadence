import SwiftUI

extension Color {
    /// Parse a `#RRGGBB` (or `RRGGBB`) sRGB hex string. Returns `nil` on any malformed input
    /// so a catalog-integrity test can flag a typo'd entry rather than silently rendering wrong.
    init?(hex raw: String) {
        var s = raw.trimmingCharacters(in: .whitespaces)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let value = UInt32(s, radix: 16) else { return nil }
        let r = Double((value >> 16) & 0xFF) / 255.0
        let g = Double((value >> 8) & 0xFF) / 255.0
        let b = Double(value & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }

    /// `.black` for light tiles, `.white` for dark tiles — chosen so the monogram letter stays legible.
    var contrastingForeground: Color { prefersDarkForeground ? .black : .white }

    /// True when this color is light enough that dark text reads better on it.
    var prefersDarkForeground: Bool {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)
        let lum = ServiceContrast.relativeLuminance(red: Double(r), green: Double(g), blue: Double(b))
        return ServiceContrast.prefersDarkForeground(luminance: lum)
    }
}

/// Pure luminance math, separated from `Color` so it is trivially unit-testable.
enum ServiceContrast {
    /// WCAG relative luminance of sRGB `0...1` channels.
    static func relativeLuminance(red: Double, green: Double, blue: Double) -> Double {
        func lin(_ c: Double) -> Double { c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4) }
        return 0.2126 * lin(red) + 0.7152 * lin(green) + 0.0722 * lin(blue)
    }

    /// Above this linearized-luminance threshold, dark text reads better than white.
    static func prefersDarkForeground(luminance: Double) -> Bool { luminance > 0.4 }
}
