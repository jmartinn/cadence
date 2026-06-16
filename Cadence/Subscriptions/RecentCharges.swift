import CadenceKit
import Foundation

/// Derives the recent *posted* charges for a subscription from its billing schedule.
///
/// Pure presentation logic (reads `@Model Subscription`, composes `BillingSchedule`). There is
/// no `Transaction` entity yet (deferred to milestone 2) — these rows are computed, not stored:
/// each is a scheduled date paired with the subscription's CURRENT amount. See spec §11.1 for
/// the debt this carries (no pending state, no price history, no one-off/refunded charges).
enum RecentCharges {
    struct Charge: Identifiable, Equatable {
        let id: Date
        let date: Date
        let amount: Decimal
        init(date: Date, amount: Decimal) {
            id = date
            self.date = date
            self.amount = amount
        }
    }

    /// Charges on or before `asOf`, most-recent-first, capped at `limit`.
    /// Empty when the anchor is in the future (also avoids a `DateInterval` start>end trap).
    static func recent(
        for sub: Subscription,
        asOf: Date,
        calendar: Calendar = .current,
        limit: Int = 3
    ) -> [Charge] {
        guard asOf >= sub.anchorDate else { return [] }
        let schedule = BillingSchedule(anchorDate: sub.anchorDate, cycle: sub.billingCycle, calendar: calendar)
        let dates = schedule.occurrences(in: DateInterval(start: sub.anchorDate, end: asOf))
        return dates.suffix(limit).reversed().map { Charge(date: $0, amount: sub.amount) }
    }
}
