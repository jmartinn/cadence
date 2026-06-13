import Testing
import Foundation
@testable import Cadence

struct ForecasterTests {

    // MARK: - Deterministic helpers

    let utc: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }()

    func day(_ year: Int, _ month: Int, _ d: Int) -> Date {
        utc.date(from: DateComponents(year: year, month: month, day: d, hour: 12))!
    }

    func dec(_ s: String) -> Decimal { Decimal(string: s)! }

    func plan(
        amount: String,
        cycle: BillingCycle,
        anchor: Date,
        status: SubscriptionStatus = .active
    ) -> SubscriptionPlan {
        SubscriptionPlan(amount: dec(amount), cycle: cycle, anchorDate: anchor, status: status)
    }

    func forecaster(
        balance: String,
        asOf: Date,
        _ plans: [SubscriptionPlan]
    ) -> Forecaster {
        Forecaster(anchorBalance: dec(balance), asOfDate: asOf, subscriptions: plans, calendar: utc)
    }

    // MARK: - Tests

    @Test func emptyForecastReturnsAnchorBalance() {
        let f = forecaster(balance: "1000.00", asOf: day(2025, 1, 1), [])
        #expect(f.projectedBalance(on: day(2025, 6, 1)) == dec("1000.00"))
    }
}
