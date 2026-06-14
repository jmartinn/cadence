import SwiftUI

/// "Renewing this month" + "See all". Each row reuses `SubscriptionRow`, showing the month's
/// charge date, and pushes to the subscription's detail via the host `NavigationStack`.
struct RenewingSection: View {
    let items: [HomeSummary.RenewingItem]
    let onSeeAll: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Renewing this month").font(.system(size: 18, weight: .bold))
                Spacer()
                Button("See all", action: onSeeAll).font(.system(size: 15))
            }
            LazyVStack(spacing: 12) {
                ForEach(items) { item in
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
