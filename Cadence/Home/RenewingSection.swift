import SwiftUI

/// "Renewing this month" + "See all". Each row reuses `SubscriptionRow`, showing the month's
/// charge date, and pushes to the subscription's detail via the host `NavigationStack`.
struct RenewingSection: View {
    let items: [HomeSummary.RenewingItem]
    let onSeeAll: () -> Void

    /// Matches the Figma: at most 4 rows inline; the rest live behind "See all".
    private static let displayLimit = 4

    var body: some View {
        VStack(alignment: .leading, spacing: Space.md) {
            HStack {
                Text("Renewing this month").font(.system(size: 18, weight: .bold))
                Spacer()
                Button("See all", action: onSeeAll).font(.system(size: 15))
            }
            LazyVStack(spacing: Space.md) {
                ForEach(items.prefix(Self.displayLimit)) { item in
                    NavigationLink(value: item.subscription) {
                        SubscriptionRow(subscription: item.subscription, nextCharge: item.chargeDate)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
