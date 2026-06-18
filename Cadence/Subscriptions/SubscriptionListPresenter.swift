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

    /// Distinct categories present among `subs` (read via `categoryKind`), returned in canonical
    /// `SubscriptionCategory.allCases` order. Drives the filter chip row; empty when `subs` is empty.
    static func availableCategories(in subs: [Subscription]) -> [SubscriptionCategory] {
        let present = Set(subs.map(\.categoryKind))
        return SubscriptionCategory.allCases.filter { present.contains($0) }
    }

    /// Whether the category filter row should be offered: only when subscriptions span at least
    /// two categories (with a single bucket there is nothing to narrow). Mirrors the row's gate.
    static func shouldOfferFilter(in subs: [Subscription]) -> Bool {
        availableCategories(in: subs).count >= 2
    }

    /// Subscriptions kept by category. `nil` (All) returns `subs` unchanged; a non-nil category
    /// keeps only those whose `categoryKind` matches. Order is preserved — callers sort afterward.
    static func filtered(_ subs: [Subscription], by category: SubscriptionCategory?) -> [Subscription] {
        guard let category else { return subs }
        return subs.filter { $0.categoryKind == category }
    }

    /// Resolve the user's selected filter against what is actually present: keep the selection only
    /// if that category still has subscriptions, otherwise fall back to All (`nil`). Prevents a
    /// stranded filter when the last subscription in a category is removed while it is selected.
    static func effectiveCategory(
        _ selected: SubscriptionCategory?,
        among available: [SubscriptionCategory]
    ) -> SubscriptionCategory? {
        guard let selected, available.contains(selected) else { return nil }
        return selected
    }

    /// Localized case-insensitive A→Z tiebreaker.
    private static func byName(_ a: Subscription, _ b: Subscription) -> Bool {
        a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
    }
}
