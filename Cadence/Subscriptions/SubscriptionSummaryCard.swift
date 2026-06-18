import SwiftUI

/// The Per month / Per year totals card at the top of the subscriptions screen.
/// Pure presentation: callers pass already-computed `Decimal` totals.
struct SubscriptionSummaryCard: View {
    let monthly: Decimal
    let yearly: Decimal
    /// Optional context label shown above the totals (e.g. the active category name).
    /// `nil` renders the card exactly as before — just the two totals.
    var title: String? = nil

    var body: some View {
        VStack(spacing: Space.sm) {
            if let title {
                Text(title)
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Space.lg)
            }
            HStack(spacing: 0) {
                half(label: "Per month", amount: monthly)
                Divider().frame(height: 40)
                half(label: "Per year", amount: yearly)
            }
        }
        .padding(.vertical, Space.lg)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }

    private func half(label: String, amount: Decimal) -> some View {
        VStack(spacing: Space.xs) {
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

#Preview("Filtered") {
    SubscriptionSummaryCard(
        monthly: Decimal(string: "40.00")!,
        yearly: Decimal(string: "480.00")!,
        title: "Entertainment"
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}
