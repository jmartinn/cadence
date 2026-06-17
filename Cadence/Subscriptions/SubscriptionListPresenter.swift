import CadenceKit
import Foundation
import SwiftData

/// Pure, stateless presentation logic for the subscriptions list. Lives in the presentation
/// layer (not pure Domain) because it reads `@Model Subscription` and composes `BillingSchedule`
/// through `Subscription.plan`. Unit-tested against an in-memory `ModelContainer`.
enum SubscriptionListPresenter {
    /// The next charge strictly after `today` for one subscription.
    /// `nil` only if the schedule yields no occurrence after `today`.
    static func nextCharge(
        for sub: Subscription,
        after today: Date,
        calendar: Calendar
    ) -> Date? {
        BillingSchedule(anchorDate: sub.anchorDate, cycle: sub.billingCycle, calendar: calendar)
            .nextOccurrence(after: today)
    }

    /// Subscriptions ordered for display under the given sort mode. Stable: ties break by name.
    static func sorted(
        _ subs: [Subscription],
        by sort: SubscriptionSort,
        today: Date,
        calendar: Calendar
    ) -> [Subscription] {
        switch sort {
        case .name:
            return subs.sorted { byName($0, $1) }

        case .price:
            return subs.sorted {
                let a = $0.plan.normalizedMonthlyAmount
                let b = $1.plan.normalizedMonthlyAmount
                if a == b { return byName($0, $1) }
                return a > b   // highest-first
            }

        case .nextCharge:
            return subs.sorted {
                let da = nextCharge(for: $0, after: today, calendar: calendar)
                let db = nextCharge(for: $1, after: today, calendar: calendar)
                switch (da, db) {
                case let (x?, y?):
                    if x == y { return byName($0, $1) }
                    return x < y           // soonest-first
                case (_?, nil):
                    return true            // a real date sorts before nil
                case (nil, _?):
                    return false           // nil sorts last
                case (nil, nil):
                    return byName($0, $1)
                }
            }
        }
    }

    /// True if `subject` may be linked under a parent. A sub that already has add-ons cannot
    /// itself become an add-on (one level only). `nil` (Add mode) can always have a parent.
    static func canHaveParent(_ subject: Subscription?) -> Bool {
        guard let subject else { return true }
        return subject.addOns.isEmpty
    }

    /// Standalone subscriptions that may serve as a parent for `subject`: not `subject` itself,
    /// and not already an add-on. Sorted A→Z for stable picker order.
    static func eligibleParents(
        for subject: Subscription?,
        among all: [Subscription]
    ) -> [Subscription] {
        all.filter { candidate in
            candidate.parent == nil
                && candidate.persistentModelID != subject?.persistentModelID
        }
        .sorted { byName($0, $1) }
    }

    /// Monthly-equivalent total for a parent and its add-ons, counting only `.active` members
    /// (matches the forecast). Used for the "…/mo with add-ons" caption on the parent detail.
    static func combinedMonthly(for parent: Subscription) -> Decimal {
        ([parent] + parent.addOns)
            .filter { $0.status == .active }
            .reduce(Decimal(0)) { $0 + $1.plan.normalizedMonthlyAmount }
    }

    /// Localized case-insensitive A→Z tiebreaker.
    private static func byName(_ a: Subscription, _ b: Subscription) -> Bool {
        a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
    }
}
