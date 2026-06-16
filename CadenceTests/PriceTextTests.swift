@testable import Cadence
import Foundation
import Testing

/// Locks `PriceText`'s money formatting — in particular the sign handling that the negative
/// month-end forecast relies on (previously fixed only in the view, untested).
struct PriceTextTests {
    @Test func splitFormatsWholeAndCents() {
        #expect(PriceText.split(Decimal(string: "90.94")!) == ("90", "94"))
        #expect(PriceText.split(Decimal(string: "1091.2")!) == ("1091", "20")) // pads to 2 digits
        #expect(PriceText.split(Decimal(string: "0.05")!) == ("0", "05"))
    }

    @Test func signedInlineStringPassesPositivesThrough() {
        let amount = Decimal(string: "1025.06")!
        #expect(PriceText.signedInlineString(amount) == PriceText.inlineString(amount))
    }

    /// The regression guard: a negative amount must format as a leading minus on the *magnitude*,
    /// not whatever `inlineString`/`split` produce for a raw negative (the whole part floors toward
    /// −∞, so a raw −50,50 would render "-51,50€"). Locale-robust: compares to the magnitude form.
    @Test func signedInlineStringPrefixesNegativesWithMinusOnMagnitude() {
        let negative = Decimal(string: "-50.50")!
        let magnitude = Decimal(string: "50.50")!
        #expect(PriceText.signedInlineString(negative) == "-" + PriceText.inlineString(magnitude))
        #expect(PriceText.signedInlineString(negative).hasPrefix("-"))
    }
}
