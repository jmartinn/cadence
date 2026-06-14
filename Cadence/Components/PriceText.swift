import SwiftUI

/// Renders a `Decimal` money amount in Cadence's house style: a smaller currency symbol,
/// a large bold whole part, superscript cents, and an optional trailing gray suffix (e.g. "/m").
/// All math stays in `Decimal` — cents are extracted via `NSDecimalRound`, never `Double`.
struct PriceText: View {
    enum SymbolPosition { case leading, trailing }

    let amount: Decimal
    var symbolPosition: SymbolPosition = .leading
    var suffix: String? = nil
    var wholeSize: CGFloat = 22
    var symbolSize: CGFloat = 14
    var centsSize: CGFloat = 12

    private static let symbol = "€"

    /// Locale's decimal separator ("," in es/EUR, "." in en-US). Falls back to ",".
    private static var decimalSeparator: String { Locale.current.decimalSeparator ?? "," }

    /// Explicit init so the amount is passed unlabeled (`PriceText(total, ...)`).
    init(
        _ amount: Decimal,
        symbolPosition: SymbolPosition = .leading,
        suffix: String? = nil,
        wholeSize: CGFloat = 22,
        symbolSize: CGFloat = 14,
        centsSize: CGFloat = 12
    ) {
        self.amount = amount
        self.symbolPosition = symbolPosition
        self.suffix = suffix
        self.wholeSize = wholeSize
        self.symbolSize = symbolSize
        self.centsSize = centsSize
    }

    var body: some View {
        let parts = Self.split(amount)
        let symbolText = Text(Self.symbol)
            .font(.system(size: symbolSize, weight: .bold))
        let wholeText = Text(parts.whole)
            .font(.system(size: wholeSize, weight: .bold))
        let centsText = Text(parts.cents)
            .font(.system(size: centsSize, weight: .bold))
            .baselineOffset(centsSize * 0.5)
        // Separator stays on the whole-number baseline (no offset) so it tucks under the
        // raised cents: e.g. "17,⁹⁹".
        let separatorText = Text(Self.decimalSeparator)
            .font(.system(size: centsSize, weight: .bold))

        let money: Text = symbolPosition == .leading
            ? Text("\(symbolText)\(wholeText)\(separatorText)\(centsText)")
            : Text("\(wholeText)\(separatorText)\(centsText)\(symbolText)")

        if let suffix {
            let suffixText = Text(suffix)
                .font(.system(size: centsSize, weight: .regular))
                .foregroundColor(.secondary)
            Text("\(money)\(suffixText)")
        } else {
            money
        }
    }

    /// Split a Decimal into a whole-number string and a 2-digit cents string, all in base-10
    /// Decimal arithmetic. e.g. 90.94 -> ("90", "94"); 1091.2 -> ("1091", "20").
    static func split(_ amount: Decimal) -> (whole: String, cents: String) {
        var value = amount
        var rounded = Decimal()
        NSDecimalRound(&rounded, &value, 2, .plain)

        var wholeDecimal = Decimal()
        var roundedCopy = rounded
        NSDecimalRound(&wholeDecimal, &roundedCopy, 0, .down)

        let fraction = rounded - wholeDecimal
        let centsInt = ((fraction as NSDecimalNumber).multiplying(by: 100)).intValue
        let wholeInt = (wholeDecimal as NSDecimalNumber).intValue

        return (String(wholeInt), String(format: "%02d", centsInt))
    }

    /// Single source of truth for inline (single-`String`) money in the house style — e.g.
    /// "90,94€" — Decimal-exact and locale-aware, matching the `PriceText` view's separator/symbol.
    /// Assumes a **non-negative** `amount` (like the view); callers format the sign themselves,
    /// because `split`'s whole-part flooring rounds toward −∞ and mis-renders negatives.
    static func inlineString(_ amount: Decimal) -> String {
        let parts = split(amount)
        return "\(parts.whole)\(decimalSeparator)\(parts.cents)\(symbol)"
    }
}

#Preview {
    VStack(spacing: 16) {
        PriceText(Decimal(string: "90.94")!, symbolPosition: .leading)
        PriceText(Decimal(string: "1091.28")!, symbolPosition: .leading)
        PriceText(Decimal(string: "17.99")!, symbolPosition: .trailing, suffix: "/m",
                  wholeSize: 16, symbolSize: 16, centsSize: 11)
    }
    .padding()
}
