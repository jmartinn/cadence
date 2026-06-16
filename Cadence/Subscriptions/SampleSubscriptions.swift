#if DEBUG
import CadenceKit
import Foundation
import SwiftData

/// Sample subscriptions for the DEBUG seed FAB and SwiftUI Previews. Slice 5 replaces the
/// FAB's seed action with a real Add sheet; this stays for Previews.
enum SampleSubscriptions {
    /// Fresh `Subscription` instances every call (never reuse `@Model` objects across contexts).
    ///
    /// Tuned to the Home Figma frame: 9 monthly subs totaling **€90.94/m**, of which the two that
    /// charge before mid-month (day 4 + 10) total **€28.98** → "paid 2/9 or €28,98". Day-of-month
    /// drives the June occurrence; most carry card details (calendar debit badge), Notion + NYT are
    /// deliberately card-less (monochrome brands → no badge).
    static func makeAll() -> [Subscription] {
        [
            // Paid this month (charge before today's 15th): 17.99 + 10.99 = 28.98
            sub("Netflix", "17.99", .monthly, 2025, 1, 4, "netflix", "Entertainment", "Visa", "4821"),
            sub("Disney+", "10.99", .monthly, 2025, 1, 10, "disney-plus", "Entertainment", "Visa", "4821"),
            // Renewing later this month: 11.99 + 13.99 + 12.00 + 8.00 + 8.99 + 2.99 + 4.00 = 61.96
            sub("NYT", "4.00", .monthly, 2025, 1, 16, "nyt", "News"),
            sub("Figma", "12.00", .monthly, 2025, 1, 18, "figma", "Productivity", "Mastercard", "5512"),
            sub("Spotify", "11.99", .monthly, 2025, 1, 20, "spotify", "Music", "Mastercard", "5512"),
            sub("iCloud+", "2.99", .monthly, 2025, 1, 22, "icloud", "Utilities", "Visa", "4821"),
            sub("Notion", "8.00", .monthly, 2025, 1, 25, "notion", "Productivity"),
            sub("YouTube Premium", "13.99", .monthly, 2025, 1, 28, "youtube", "Entertainment", "Visa", "4821"),
            sub("Amazon Prime", "8.99", .monthly, 2025, 1, 30, "amazon-prime", "Shopping", "Visa", "4821"),
        ]
    }

    /// Insert the samples and persist so they survive relaunch on device.
    @MainActor
    static func seed(into context: ModelContext) {
        for sub in makeAll() {
            context.insert(sub)
        }
        try? context.save()
    }

    private static func sub(
        _ name: String,
        _ amount: String,
        _ cycle: BillingCycle,
        _ year: Int,
        _ month: Int,
        _ day: Int,
        _ key: String,
        _ category: String,
        _ paymentBrand: String? = nil,
        _ paymentLast4: String? = nil
    ) -> Subscription {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let anchor = calendar.date(from: DateComponents(year: year, month: month, day: day)) ?? .distantPast
        return Subscription(
            name: name,
            amount: Decimal(string: amount)!,
            billingCycle: cycle,
            anchorDate: anchor,
            status: .active,
            category: category,
            serviceKey: key,
            paymentBrand: paymentBrand,
            paymentLast4: paymentLast4
        )
    }
}
#endif
