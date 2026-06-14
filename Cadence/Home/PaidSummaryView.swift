import SwiftUI

/// The "You have N subscriptions this month and you have paid P/N or €A." sentence plus a
/// monogram cluster (first 2 services + a "+K" overflow chip).
struct PaidSummaryView: View {
    let paid: Int
    let total: Int
    let paidAmount: Decimal
    let clusterNames: [String]

    private static let clusterLimit = 2

    var body: some View {
        VStack(spacing: 12) {
            sentence
            cluster
        }
        .frame(maxWidth: .infinity)
    }

    private var sentence: Text {
        let lead = Text("You have ").foregroundColor(.secondary)
        let count = Text("\(total) subscriptions").fontWeight(.bold).foregroundColor(.primary)
        let mid = Text(" this month and you have paid ").foregroundColor(.secondary)
        let frac = Text("\(paid)/\(total)").fontWeight(.bold).foregroundColor(.primary)
        let orText = Text(" or ").foregroundColor(.secondary)
        let amount = Text(Self.amountString(paidAmount)).fontWeight(.bold).foregroundColor(.primary)
        let dot = Text(".").foregroundColor(.secondary)
        return Text("\(lead)\(count)\(mid)\(frac)\(orText)\(amount)\(dot)")
    }

    @ViewBuilder private var cluster: some View {
        let shown = Array(clusterNames.prefix(Self.clusterLimit))
        let overflow = max(0, clusterNames.count - Self.clusterLimit)
        HStack(spacing: -8) {
            ForEach(Array(shown.enumerated()), id: \.offset) { _, name in
                SubscriptionMonogram(name: name, size: 28)
                    .overlay(Circle().stroke(Color(.systemBackground), lineWidth: 2))
            }
            if overflow > 0 {
                Text("+\(overflow)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(.systemBackground))      // inverted: visible in dark mode
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(Color.primary))
                    .overlay(Circle().stroke(Color(.systemBackground), lineWidth: 2))
            }
        }
    }

    /// €-suffixed, Decimal-exact, locale-aware separator (reuses PriceText.split).
    private static func amountString(_ d: Decimal) -> String {
        let parts = PriceText.split(d)
        let sep = Locale.current.decimalSeparator ?? ","
        return "\(parts.whole)\(sep)\(parts.cents)€"
    }
}

#Preview {
    PaidSummaryView(paid: 2, total: 9, paidAmount: Decimal(string: "28.98")!,
                    clusterNames: ["Netflix", "Spotify", "Figma", "Twitch", "iCloud+", "Amazon Prime", "X", "Y", "Z"])
        .padding()
}
