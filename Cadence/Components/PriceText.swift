import SwiftUI
import UIKit

/// Renders a `Decimal` money amount in Cadence's house style: a smaller currency symbol,
/// a large bold whole part, superscript cents, and an optional trailing gray suffix (e.g. "/m").
/// All math stays in `Decimal` — cents are extracted via `NSDecimalRound`, never `Double`.
struct PriceText: View {
    enum SymbolPosition { case leading, trailing }

    /// How a smaller run (currency symbol or cents) sits relative to the whole number. Both cases
    /// are *derived* from real type metrics — there are no hand-tuned point offsets to maintain.
    enum VerticalLift {
        /// Sits on the whole number's baseline (the house style for the symbol at list/detail sizes).
        case baseline
        /// Top-aligned to the whole number's cap height. The lift is computed from the two fonts'
        /// cap heights, so the run's cap lines up with the big number's cap at *any* size pairing.
        case capAligned
    }

    let amount: Decimal
    var symbolPosition: SymbolPosition = .leading
    var suffix: String?
    var wholeSize: CGFloat = 22
    var symbolSize: CGFloat = 14
    var centsSize: CGFloat = 12
    /// Vertical placement of the currency symbol. Defaults to `.baseline` (the house style at
    /// list/detail sizes); large hero prices pass `.capAligned` to float it as a top-aligned
    /// super-index, matching the Figma.
    var symbolLift: VerticalLift = .baseline
    /// Vertical placement of the cents. Defaults to `.capAligned` so the cents read as a true
    /// top-aligned superscript at every size pairing, derived from the fonts' cap heights.
    var centsLift: VerticalLift = .capAligned

    private static let symbol = "€"

    /// Locale's decimal separator ("," in es/EUR, "." in en-US). Falls back to ",".
    private static var decimalSeparator: String { Locale.current.decimalSeparator ?? "," }

    /// Cap height (points) of the bold system font at `size` — the real typographic metric we
    /// align to. Read from the matching `UIFont`, since SwiftUI's `Font` doesn't expose metrics.
    private static func capHeight(_ size: CGFloat) -> CGFloat {
        UIFont.systemFont(ofSize: size, weight: .bold).capHeight
    }

    /// Baseline offset (points) for a `size`-pt run under the given lift, relative to the
    /// `wholeSize` baseline. `.capAligned` raises by the difference in cap heights so the run's
    /// cap top meets the whole number's cap top.
    private func baselineOffset(for lift: VerticalLift, size: CGFloat) -> CGFloat {
        switch lift {
        case .baseline: return 0
        case .capAligned: return Self.capHeight(wholeSize) - Self.capHeight(size)
        }
    }

    /// Explicit init so the amount is passed unlabeled (`PriceText(total, ...)`).
    init(
        _ amount: Decimal,
        symbolPosition: SymbolPosition = .leading,
        suffix: String? = nil,
        wholeSize: CGFloat = 22,
        symbolSize: CGFloat = 14,
        centsSize: CGFloat = 12,
        symbolLift: VerticalLift = .baseline,
        centsLift: VerticalLift = .capAligned
    ) {
        self.amount = amount
        self.symbolPosition = symbolPosition
        self.suffix = suffix
        self.wholeSize = wholeSize
        self.symbolSize = symbolSize
        self.centsSize = centsSize
        self.symbolLift = symbolLift
        self.centsLift = centsLift
    }

    var body: some View {
        let parts = Self.split(amount)
        let symbolText = Text(Self.symbol)
            .font(.system(size: symbolSize, weight: .bold))
            .baselineOffset(baselineOffset(for: symbolLift, size: symbolSize))
        let wholeText = Text(parts.whole)
            .font(.system(size: wholeSize, weight: .bold))
        let centsText = Text(parts.cents)
            .font(.system(size: centsSize, weight: .bold))
            .baselineOffset(baselineOffset(for: centsLift, size: centsSize))
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

    /// Sign-aware inline money. `split`/`inlineString` assume a **non-negative** amount (the whole
    /// part floors toward −∞, so a raw negative renders wrong — e.g. −50,50 → "-51,50€"). This
    /// formats the magnitude and re-applies a leading minus, so any caller that can hold a negative
    /// value — e.g. an over-budget month-end forecast — MUST route through here.
    static func signedInlineString(_ amount: Decimal) -> String {
        amount < 0 ? "-" + inlineString(-amount) : inlineString(amount)
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
