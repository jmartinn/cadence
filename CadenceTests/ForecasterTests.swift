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

    @Test func singleMonthlySubscriptionSubtractsEachCharge() {
        let sub = plan(amount: "9.99", cycle: .monthly, anchor: day(2025, 1, 10))
        let f = forecaster(balance: "500.00", asOf: day(2025, 1, 1), [sub])
        #expect(f.projectedBalance(on: day(2025, 4, 15)) == dec("460.04")) // 500 - 4*9.99
    }

    @Test func reconciliationExampleEndsMonthAt1025() {
        let netflix = plan(amount: "49.99", cycle: .monthly, anchor: day(2025, 6, 12))
        let spotify = plan(amount: "11.97", cycle: .monthly, anchor: day(2025, 6, 20))
        let f = forecaster(balance: "1087.02", asOf: day(2025, 6, 1), [netflix, spotify])
        #expect(f.projectedBalance(on: day(2025, 6, 30)) == dec("1025.06"))
    }

    @Test func yearlySubscriptionChargesOncePerYearInWindow() {
        let sub = plan(amount: "99.00", cycle: .yearly, anchor: day(2025, 3, 3))
        let f = forecaster(balance: "1000.00", asOf: day(2025, 1, 1), [sub])
        #expect(f.projectedBalance(on: day(2026, 12, 31)) == dec("802.00")) // 1000 - 2*99
    }
}
