import CadenceKit
import Foundation
import SwiftData

/// Derived facts for the Home dashboard header. Pure presentation logic (mirrors
/// `SubscriptionListPresenter`): reads `@Model Subscription` for names but no SwiftUI, so it
/// unit-tests with directly-constructed instances. Output is value-typed and `Equatable`.
struct HomeSummary: Equatable {
    let monthlyTotal: Decimal
    let paid: Int
    let total: Int
    let paidAmount: Decimal
    let clusterNames: [String]          // services renewing in referenceDate's month, charge-date order
    let projectedEndOfMonth: Decimal?   // nil when there is no anchor

    /// - Parameters:
    ///   - referenceDate: Drives the month interval, the this-month charge list, clusterNames,
    ///     and the projection target (last instant of referenceDate's month).
    ///   - today: Drives now-sensitive values only: `paidThisMonth(asOf:)` and `paidAmount`
    ///     (charges with date <= now). Defaults to `referenceDate` so current-month callers
    ///     can omit it — semantics are identical to the old single-`today` API.
    static func make(
        subscriptions: [Subscription],
        anchor: BalanceAnchor?,
        referenceDate: Date,
        today: Date? = nil,
        calendar: Calendar = .current
    ) -> HomeSummary {
        let now = today ?? referenceDate
        let active = subscriptions.filter { $0.status == .active }
        let forecaster = Forecaster(
            anchorBalance: anchor?.balance ?? 0,
            asOfDate: anchor?.asOfDate ?? .distantPast,
            subscriptions: active.map(\.plan),
            monthlyIncome: anchor?.monthlyIncome ?? 0,
            incomePayday: anchor.flatMap { $0.incomePayday == .distantPast ? nil : $0.incomePayday },
            calendar: calendar
        )
        let counts = forecaster.paidThisMonth(asOf: now)

        // This-month charge per active sub (earliest occurrence in referenceDate's month).
        let month = calendar.dateInterval(of: .month, for: referenceDate)
        var thisMonth: [(name: String, charge: Date, amount: Decimal)] = []
        if let month {
            for sub in active {
                let schedule = BillingSchedule(anchorDate: sub.anchorDate, cycle: sub.billingCycle, calendar: calendar)
                if let charge = schedule.occurrences(in: month).first(where: { $0 < month.end }) {
                    thisMonth.append((sub.name, charge, sub.amount))
                }
            }
            thisMonth.sort { $0.charge < $1.charge }
        }

        // Only count a charge as paid if it has already occurred relative to now.
        let paidAmount = thisMonth.filter { $0.charge <= now }
            .reduce(into: Decimal.zero) { $0 += $1.amount }

        let projected: Decimal? = anchor.map { _ in
            // last instant of referenceDate's month, so a charge on the 1st of next month is excluded
            let target = month.map { $0.end.addingTimeInterval(-1) } ?? referenceDate
            return forecaster.projectedBalance(on: target)
        }

        return HomeSummary(
            monthlyTotal: forecaster.monthlyTotal,
            paid: counts.paid,
            total: counts.total,
            paidAmount: paidAmount,
            clusterNames: thisMonth.map(\.name),
            projectedEndOfMonth: projected
        )
    }
}

extension HomeSummary {
    /// One renewing-this-month row: the subscription + its charge date in referenceDate's month.
    struct RenewingItem: Identifiable {
        let subscription: Subscription
        let chargeDate: Date
        var id: PersistentIdentifier { subscription.persistentModelID }
    }

    /// Active subscriptions with a charge in the calendar month containing `referenceDate`,
    /// sorted by charge date.
    static func renewing(
        subscriptions: [Subscription],
        referenceDate: Date,
        calendar: Calendar = .current
    ) -> [RenewingItem] {
        guard let month = calendar.dateInterval(of: .month, for: referenceDate) else { return [] }
        var items: [RenewingItem] = []
        for sub in subscriptions where sub.status == .active {
            let schedule = BillingSchedule(anchorDate: sub.anchorDate, cycle: sub.billingCycle, calendar: calendar)
            if let charge = schedule.occurrences(in: month).first(where: { $0 < month.end }) {
                items.append(RenewingItem(subscription: sub, chargeDate: charge))
            }
        }
        return items.sorted { $0.chargeDate < $1.chargeDate }
    }
}
