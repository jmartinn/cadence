import SwiftUI

/// The Per month / Per year totals card at the top of the subscriptions screen.
/// Pure presentation: callers pass already-computed `Decimal` totals.
struct SubscriptionSummaryCard: View {
    let monthly: Decimal
    let yearly: Decimal

    var body: some View {
        HStack(spacing: 0) {
            half(label: "Per month", amount: monthly)
            Divider().frame(height: 40)
            half(label: "Per year", amount: yearly)
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }

    private func half(label: String, amount: Decimal) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.footnote)
                .foregroundColor(.secondary)
            PriceText(amount, symbolPosition: .leading)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    SubscriptionSummaryCard(
        monthly: Decimal(string: "90.94")!,
        yearly: Decimal(string: "1091.28")!
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}
