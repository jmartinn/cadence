import CadenceKit
import SwiftUI

/// A single subscription card in the list and in Home's "Renewing this month" section. The host
/// wraps it in a `NavigationLink` to the detail screen. Receives the precomputed `nextCharge` so
/// it only formats — it does not own schedule math.
struct SubscriptionRow: View {
    let subscription: Subscription
    let nextCharge: Date?

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.setLocalizedDateFormatFromTemplate("MMMMd")
        return f
    }()

    var body: some View {
        HStack(spacing: Space.md) {
            ServiceIcon(serviceKey: subscription.serviceKey, name: subscription.name)
            VStack(alignment: .leading, spacing: Space.xs) {
                Text(subscription.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                Text(nextChargeText)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                if let parent = subscription.parent {
                    Text("Part of \(parent.name)")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            Spacer(minLength: Space.sm)
            PriceText(
                subscription.amount,
                symbolPosition: .trailing,
                suffix: cycleSuffix,
                wholeSize: 16,
                symbolSize: 16,
                centsSize: 11
            )
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(.tertiaryLabel))
        }
        .padding(Space.lg)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }

    private var cycleSuffix: String {
        switch subscription.billingCycle {
        case .monthly: return "/m"
        case .yearly: return "/y"
        }
    }

    private var nextChargeText: String {
        guard let nextCharge else { return "No upcoming charge" }
        return "Next \(Self.dateFormatter.string(from: nextCharge))"
    }
}

#Preview {
    let sub = Subscription(
        name: "Netflix",
        amount: Decimal(string: "17.99")!,
        billingCycle: .monthly,
        anchorDate: Date(timeIntervalSince1970: 1_733_270_400), // 2024-12-04
        status: .active,
        category: "Entertainment"
    )
    return SubscriptionRow(subscription: sub, nextCharge: Date(timeIntervalSince1970: 1_764_806_400))
        .padding()
        .background(Color(.systemGroupedBackground))
}
