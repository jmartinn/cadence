#if DEBUG
import CadenceKit
import Foundation
import SwiftData

/// Sample subscriptions for the DEBUG seed FAB and SwiftUI Previews. Slice 5 replaces the
/// FAB's seed action with a real Add sheet; this stays for Previews.
enum SampleSubscriptions {
    /// Fresh `Subscription` instances every call (never reuse `@Model` objects across contexts).
    ///
    /// 11 monthly subs: the original 9 (Netflix, Disney+, NYT, Figma, Spotify, iCloud+, Notion,
    /// YouTube Premium, Amazon Prime) plus two add-ons billed through Amazon Prime — Paramount+
    /// (€7.99) and Crunchyroll (€4.99) — linked via `.parent = prime`. Add-ons are display-only
    /// children of Prime in the UI but still count independently toward the forecast total.
    /// Day-of-month drives the occurrence; most carry card details (calendar debit badge), Notion
    /// + NYT are deliberately card-less (monochrome brands → no badge).
    static func makeAll() -> [Subscription] {
        let netflix = sub("Netflix", "17.99", .monthly, 2025, 1, 4, "netflix", "Entertainment", "Visa", "4821")
        let disney = sub("Disney+", "10.99", .monthly, 2025, 1, 10, "disney-plus", "Entertainment", "Visa", "4821")
        let nyt = sub("NYT", "4.00", .monthly, 2025, 1, 16, "nyt", "News")
        let figma = sub("Figma", "12.00", .monthly, 2025, 1, 18, "figma", "Productivity", "Mastercard", "5512")
        let spotify = sub("Spotify", "11.99", .monthly, 2025, 1, 20, "spotify", "Music", "Mastercard", "5512")
        let icloud = sub("iCloud+", "2.99", .monthly, 2025, 1, 22, "icloud", "Utilities", "Visa", "4821")
        let notion = sub("Notion", "8.00", .monthly, 2025, 1, 25, "notion", "Productivity")
        let youtube = sub("YouTube Premium", "13.99", .monthly, 2025, 1, 28, "youtube", "Entertainment", "Visa", "4821")
        let prime = sub("Amazon Prime", "8.99", .monthly, 2025, 1, 30, "amazon-prime", "Shopping", "Visa", "4821")
        // Two Amazon Channels billed through Prime, linked as display-only add-ons.
        let paramount = sub("Paramount+", "7.99", .monthly, 2025, 1, 30, "paramount-plus", "Entertainment", "Visa", "4821")
        let crunchyroll = sub("Crunchyroll", "4.99", .monthly, 2025, 1, 30, "crunchyroll", "Entertainment", "Visa", "4821")
        paramount.parent = prime
        crunchyroll.parent = prime
        return [netflix, disney, nyt, figma, spotify, icloud, notion, youtube,
                prime, paramount, crunchyroll]
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
