#if DEBUG
import Foundation
import SwiftData

/// Sample subscriptions for the DEBUG seed FAB and SwiftUI Previews. Slice 5 replaces the
/// FAB's seed action with a real Add sheet; this stays for Previews.
enum SampleSubscriptions {
    /// Fresh `Subscription` instances every call (never reuse `@Model` objects across contexts).
    static func makeAll() -> [Subscription] {
        [
            sub("Netflix", "17.99", .monthly, 2025, 12, 4, "netflix", "Entertainment"),
            sub("Spotify", "10.99", .monthly, 2025, 12, 8, "spotify", "Music"),
            sub("Figma", "15.00", .monthly, 2025, 11, 22, "figma", "Productivity"),
            sub("Twitch", "8.99", .monthly, 2025, 12, 1, "twitch", "Entertainment"),
            sub("iCloud+", "2.99", .monthly, 2025, 11, 15, "icloud", "Utilities"),
            sub("Amazon Prime", "49.00", .yearly, 2025, 3, 2, "amazon-prime", "Shopping"),
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
        _ category: String
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
            serviceKey: key
        )
    }
}
#endif
