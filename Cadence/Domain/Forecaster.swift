import Foundation

/// Projects the balance forward and derives the totals/counts the UI shows.
///
/// Pure value type — no SwiftData, no UI. Initialized with the anchor `(balance, asOfDate)`
/// and the current subscriptions, then queried repeatedly. Every projection is anchored to
/// the same continuous timeline; there are no month boundaries in the model.
struct Forecaster: Sendable {
    let anchorBalance: Decimal
    let asOfDate: Date
    let subscriptions: [SubscriptionPlan]

    /// Injected so tests can pin a fixed timezone (UTC) and stay deterministic.
    var calendar: Calendar = .current

    /// Projected balance on `targetDate`:
    ///   anchorBalance − Σ (amount of every active charge in the half-open window (asOfDate, targetDate])
    ///
    /// A charge exactly on `asOfDate` is already baked into the balance, so it is excluded;
    /// a charge exactly on `targetDate` is included. If `targetDate <= asOfDate`, nothing is
    /// projected and the anchor balance is returned unchanged.
    func projectedBalance(on targetDate: Date) -> Decimal {
        guard targetDate > asOfDate else { return anchorBalance }
        let window = DateInterval(start: asOfDate, end: targetDate)
        var balance = anchorBalance
        for plan in subscriptions where plan.status == .active {
            let schedule = BillingSchedule(anchorDate: plan.anchorDate, cycle: plan.cycle, calendar: calendar)
            // occurrences(in:) is inclusive of both bounds; drop the left bound to make it half-open.
            let charges = schedule.occurrences(in: window).filter { $0 > asOfDate }
            balance -= plan.amount * Decimal(charges.count)
        }
        return balance
    }
}
