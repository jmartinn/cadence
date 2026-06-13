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

    @Test func chargeExactlyOnAsOfDateIsExcluded() {
        let sub = plan(amount: "10.00", cycle: .monthly, anchor: day(2025, 1, 1))
        let f = forecaster(balance: "100.00", asOf: day(2025, 1, 1), [sub])
        #expect(f.projectedBalance(on: day(2025, 2, 1)) == dec("90.00"))
    }

    @Test func chargeExactlyOnTargetDateIsIncluded() {
        let sub = plan(amount: "10.00", cycle: .monthly, anchor: day(2025, 1, 15))
        let f = forecaster(balance: "100.00", asOf: day(2025, 1, 1), [sub])
        #expect(f.projectedBalance(on: day(2025, 1, 15)) == dec("90.00"))
    }

    @Test func targetBeforeOrEqualAnchorReturnsBalance() {
        let sub = plan(amount: "10.00", cycle: .monthly, anchor: day(2025, 1, 10))
        let f = forecaster(balance: "100.00", asOf: day(2025, 6, 1), [sub])
        #expect(f.projectedBalance(on: day(2025, 1, 1)) == dec("100.00"))
        #expect(f.projectedBalance(on: day(2025, 6, 1)) == dec("100.00"))
    }

    @Test func pausedAndEndedSubscriptionsAreIgnoredInProjection() {
        let active = plan(amount: "10.00", cycle: .monthly, anchor: day(2025, 1, 10), status: .active)
        let paused = plan(amount: "20.00", cycle: .monthly, anchor: day(2025, 1, 10), status: .paused)
        let ended  = plan(amount: "30.00", cycle: .monthly, anchor: day(2025, 1, 10), status: .ended)
        let f = forecaster(balance: "100.00", asOf: day(2025, 1, 1), [active, paused, ended])
        #expect(f.projectedBalance(on: day(2025, 2, 28)) == dec("80.00"))
    }

    @Test func monthlyTotalNormalizesYearlyToMonthly() {
        let monthly = plan(amount: "9.99",  cycle: .monthly, anchor: day(2025, 1, 1))
        let yearly  = plan(amount: "120.00", cycle: .yearly,  anchor: day(2025, 1, 1))
        let f = forecaster(balance: "0.00", asOf: day(2025, 1, 1), [monthly, yearly])
        #expect(f.monthlyTotal == dec("19.99")) // 9.99 + 120/12
    }

    @Test func yearlyTotalNormalizesMonthlyToYearly() {
        let monthly = plan(amount: "10.00", cycle: .monthly, anchor: day(2025, 1, 1))
        let yearly  = plan(amount: "99.00", cycle: .yearly,  anchor: day(2025, 1, 1))
        let f = forecaster(balance: "0.00", asOf: day(2025, 1, 1), [monthly, yearly])
        #expect(f.yearlyTotal == dec("219.00")) // 10*12 + 99
    }

    @Test func totalsIgnorePausedAndEnded() {
        let active = plan(amount: "10.00", cycle: .monthly, anchor: day(2025, 1, 1), status: .active)
        let paused = plan(amount: "50.00", cycle: .monthly, anchor: day(2025, 1, 1), status: .paused)
        let ended  = plan(amount: "70.00", cycle: .yearly,  anchor: day(2025, 1, 1), status: .ended)
        let f = forecaster(balance: "0.00", asOf: day(2025, 1, 1), [active, paused, ended])
        #expect(f.monthlyTotal == dec("10.00"))
        #expect(f.yearlyTotal == dec("120.00"))
    }

    @Test func paidThisMonthCountsChargedVsDueThisMonth() {
        let early = plan(amount: "10.00", cycle: .monthly, anchor: day(2025, 1, 5))
        let late  = plan(amount: "10.00", cycle: .monthly, anchor: day(2025, 1, 25))
        let f = forecaster(balance: "0.00", asOf: day(2025, 1, 1), [early, late])
        let result = f.paidThisMonth(asOf: day(2025, 1, 15))
        #expect(result.paid == 1)
        #expect(result.total == 2)
    }

    @Test func paidThisMonthExcludesSubsNotDueThisMonth() {
        let monthly = plan(amount: "10.00", cycle: .monthly, anchor: day(2025, 1, 5))
        let yearly  = plan(amount: "99.00", cycle: .yearly,  anchor: day(2025, 3, 3))
        let f = forecaster(balance: "0.00", asOf: day(2025, 1, 1), [monthly, yearly])
        let result = f.paidThisMonth(asOf: day(2025, 1, 15))
        #expect(result.paid == 1)
        #expect(result.total == 1)
    }

    @Test func paidThisMonthIgnoresPausedAndEnded() {
        let active = plan(amount: "10.00", cycle: .monthly, anchor: day(2025, 1, 5), status: .active)
        let paused = plan(amount: "10.00", cycle: .monthly, anchor: day(2025, 1, 5), status: .paused)
        let f = forecaster(balance: "0.00", asOf: day(2025, 1, 1), [active, paused])
        let result = f.paidThisMonth(asOf: day(2025, 1, 15))
        #expect(result.paid == 1)
        #expect(result.total == 1)
    }

    @Test func projectedBalanceCanGoNegative() {
        // No overdraft guard: charges beyond the balance produce a negative projection.
        let sub = plan(amount: "30.00", cycle: .monthly, anchor: day(2025, 1, 10))
        let f = forecaster(balance: "50.00", asOf: day(2025, 1, 1), [sub])
        // Window (Jan 1, Mar 15]: Jan 10, Feb 10, Mar 10 → 3 charges → 50 - 90.
        #expect(f.projectedBalance(on: day(2025, 3, 15)) == dec("-40.00"))
    }

    @Test func paidThisMonthCountsAChargeDatedToday() {
        // Boundary: a charge falling exactly on `today` counts as already paid (charge <= today).
        let sub = plan(amount: "10.00", cycle: .monthly, anchor: day(2025, 1, 15))
        let f = forecaster(balance: "0.00", asOf: day(2025, 1, 1), [sub])
        let result = f.paidThisMonth(asOf: day(2025, 1, 15))
        #expect(result.paid == 1)
        #expect(result.total == 1)
    }
}
