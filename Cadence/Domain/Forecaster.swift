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

    /// Recurring monthly income credited into the projection (0 = none).
    var monthlyIncome: Decimal = 0
    /// Reference payday for `monthlyIncome`; `nil` = no income. Income recurs monthly from here.
    var incomePayday: Date? = nil

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
        // Credit income: paydays in the half-open window (asOfDate, targetDate]. Income on or
        // before asOfDate is already in anchorBalance, so it is excluded — no double-counting.
        if monthlyIncome > 0, let payday = incomePayday {
            let schedule = BillingSchedule(anchorDate: payday, cycle: .monthly, calendar: calendar)
            let credits = schedule.occurrences(in: window).filter { $0 > asOfDate }
            balance += monthlyIncome * Decimal(credits.count)
        }
        return balance
    }

    /// Sum of active subscriptions normalized to a monthly amount. Exact `Decimal`; the UI rounds for display.
    var monthlyTotal: Decimal {
        subscriptions
            .filter { $0.status == .active }
            .reduce(into: .zero) { $0 += $1.normalizedMonthlyAmount }
    }

    /// Sum of active subscriptions normalized to a yearly amount. Exact `Decimal`; the UI rounds for display.
    var yearlyTotal: Decimal {
        subscriptions
            .filter { $0.status == .active }
            .reduce(into: .zero) { $0 += $1.normalizedYearlyAmount }
    }

    /// (paid, total) for the calendar month containing `today`.
    /// `total` = active subscriptions with at least one charge this month;
    /// `paid`  = those whose this-month charge is on or before `today`.
    func paidThisMonth(asOf today: Date) -> (paid: Int, total: Int) {
        guard let month = calendar.dateInterval(of: .month, for: today) else { return (0, 0) }
        var paid = 0
        var total = 0
        for plan in subscriptions where plan.status == .active {
            let schedule = BillingSchedule(anchorDate: plan.anchorDate, cycle: plan.cycle, calendar: calendar)
            guard let charge = schedule.occurrences(in: month).first else { continue }
            total += 1
            if charge <= today { paid += 1 }
        }
        return (paid, total)
    }
}
