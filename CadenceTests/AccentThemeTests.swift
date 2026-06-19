@testable import Cadence
import SwiftUI
import Testing

struct AccentThemeTests {
    /// Resolve a SwiftUI Color to 0–255 sRGB components for stable comparison.
    private func rgb(_ color: Color) -> [Int] {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
        return [Int((r * 255).rounded()), Int((g * 255).rounded()), Int((b * 255).rounded())]
    }

    /// The persistence contract: these strings are stored in @AppStorage and must never change.
    @Test func rawValuesAreStable() {
        #expect(AccentTheme.graphite.rawValue == "graphite")
        #expect(AccentTheme.blue.rawValue == "blue")
        #expect(AccentTheme.indigo.rawValue == "indigo")
        #expect(AccentTheme.purple.rawValue == "purple")
        #expect(AccentTheme.pink.rawValue == "pink")
        #expect(AccentTheme.red.rawValue == "red")
        #expect(AccentTheme.orange.rawValue == "orange")
        #expect(AccentTheme.green.rawValue == "green")
        #expect(AccentTheme.teal.rawValue == "teal")
    }

    @Test func roundTripsThroughRawValue() {
        for theme in AccentTheme.allCases {
            #expect(AccentTheme(rawValue: theme.rawValue) == theme)
        }
    }

    @Test func unknownRawValueIsNil() {
        #expect(AccentTheme(rawValue: "chartreuse") == nil)
    }

    @Test func hasNineCasesWithGraphiteDefault() {
        #expect(AccentTheme.allCases.count == 9)
        #expect(AccentTheme.default == .graphite)
        #expect(AccentTheme.allCases.contains(.default))
    }

    @Test func everyCaseHasDisplayName() {
        for theme in AccentTheme.allCases {
            #expect(!theme.displayName.isEmpty)
        }
    }

    @Test func colorMapsToExpectedSystemColor() {
        #expect(rgb(AccentTheme.graphite.color) == rgb(Color.primary))
        #expect(rgb(AccentTheme.blue.color) == rgb(Color.blue))
        #expect(rgb(AccentTheme.red.color) == rgb(Color.red))
        #expect(rgb(AccentTheme.teal.color) == rgb(Color.teal))
    }
}
