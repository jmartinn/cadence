@testable import Cadence
import SwiftUI
import Testing

struct ColorHexTests {
    /// Resolve a SwiftUI Color to sRGB components via UIColor for assertions.
    private func rgb(_ color: Color) -> (r: Double, g: Double, b: Double) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
        return (Double(r), Double(g), Double(b))
    }

    @Test func parsesSixDigitHexWithHash() {
        let c = Color(hex: "#FF0000")
        #expect(c != nil)
        let (r, g, b) = rgb(c!)
        #expect(abs(r - 1.0) < 0.01)
        #expect(abs(g - 0.0) < 0.01)
        #expect(abs(b - 0.0) < 0.01)
    }

    @Test func parsesWithoutHashAndIsCaseInsensitive() {
        #expect(Color(hex: "00ff00") != nil)
        #expect(Color(hex: "00FF00") != nil)
    }

    @Test func rejectsMalformedHex() {
        #expect(Color(hex: "#ZZZ") == nil)
        #expect(Color(hex: "12345") == nil) // wrong length
        #expect(Color(hex: "") == nil)
    }

    @Test func luminanceAnchors() {
        #expect(abs(ServiceContrast.relativeLuminance(red: 1, green: 1, blue: 1) - 1.0) < 0.001)
        #expect(abs(ServiceContrast.relativeLuminance(red: 0, green: 0, blue: 0) - 0.0) < 0.001)
    }

    @Test func foregroundContrasts() {
        #expect(Color(hex: "#FFFFFF")!.prefersDarkForeground == true) // light tile → dark letter
        #expect(Color(hex: "#000000")!.prefersDarkForeground == false) // dark tile → white letter
    }
}
