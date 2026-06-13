import Foundation
import SwiftData

/// App-specific persistence operations. `insert(_:)` and `delete(_:)` already exist on
/// `ModelContext`; these add the reads Cadence needs plus the single-anchor upsert.
/// Status filtering is done in Swift (not a `#Predicate`) because enum-case predicates
/// have historically miscompiled in SwiftData.
extension ModelContext {
    /// All subscriptions, sorted by name for stable list display.
    func allSubscriptions() throws -> [Subscription] {
        try fetch(FetchDescriptor<Subscription>(sortBy: [SortDescriptor(\.name)]))
    }

    /// Active subscriptions mapped to the pure value type `Forecaster` consumes.
    /// Mapping happens here, on this context's actor; the result is a `Sendable` snapshot.
    func activePlans() throws -> [SubscriptionPlan] {
        try allSubscriptions()
            .filter { $0.status == .active }
            .map(\.plan)
    }

    /// The current balance anchor, or `nil` if none has been set.
    /// Returns the most recent by `asOfDate` so a sync race (Slice 7) resolves deterministically.
    func currentAnchor() throws -> BalanceAnchor? {
        var descriptor = FetchDescriptor<BalanceAnchor>(
            sortBy: [SortDescriptor(\.asOfDate, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try fetch(descriptor).first
    }

    /// Set or re-anchor the balance. Upserts the single anchor row in place — CloudKit
    /// forbids `@Attribute(.unique)`, so the "one continuous anchor" invariant is enforced here.
    @discardableResult
    func setAnchor(balance: Decimal, asOfDate: Date) throws -> BalanceAnchor {
        if let existing = try currentAnchor() {
            existing.balance = balance
            existing.asOfDate = asOfDate
            return existing
        }
        let anchor = BalanceAnchor(balance: balance, asOfDate: asOfDate)
        insert(anchor)
        return anchor
    }
}
