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
    /// Uses an unsorted fetch — the Forecaster sums plans, so display order is irrelevant
    /// and sorting by name here would be wasted work.
    func activePlans() throws -> [SubscriptionPlan] {
        try fetch(FetchDescriptor<Subscription>())
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

    /// Set or re-anchor the balance (and recurring income). Upserts the single anchor row in
    /// place — CloudKit forbids `@Attribute(.unique)`, so "one continuous anchor" is enforced here.
    ///
    /// This is a **full-replace upsert (PUT, not PATCH)**: every call overwrites all four fields, so
    /// omitting `monthlyIncome`/`incomePayday` resets them to "no income" (0 / `.distantPast`) — see
    /// `PersistenceTests.setAnchorWritesIncomeFieldsAndUpsertsInPlace`. Callers must always pass the
    /// complete anchor state; the only mutation path (`AnchorDraft.apply`) does.
    @discardableResult
    func setAnchor(
        balance: Decimal,
        asOfDate: Date,
        monthlyIncome: Decimal = 0,
        incomePayday: Date = .distantPast
    ) throws -> BalanceAnchor {
        if let existing = try currentAnchor() {
            existing.balance = balance
            existing.asOfDate = asOfDate
            existing.monthlyIncome = monthlyIncome
            existing.incomePayday = incomePayday
            return existing
        }
        let anchor = BalanceAnchor(balance: balance, asOfDate: asOfDate,
                                   monthlyIncome: monthlyIncome, incomePayday: incomePayday)
        insert(anchor)
        return anchor
    }
}
