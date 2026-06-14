import Testing
import Foundation
@testable import Cadence

struct ForecasterIncomeTests {
    let utc: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }()
    func day(_ y: Int, _ m: Int, _ d: Int) -> Date {
        utc.date(from: DateComponents(year: y, month: m, day: d, hour: 12))!
    }
    func dec(_ s: String) -> Decimal { Decimal(string: s)! }

    func forecaster(balance: String, asOf: Date, income: String, payday: Date?,
                    _ plans: [SubscriptionPlan] = []) -> Forecaster {
        Forecaster(anchorBalance: dec(balance), asOfDate: asOf, subscriptions: plans,
                   monthlyIncome: dec(income), incomePayday: payday, calendar: utc)
    }

    @Test func incomeAfterAsOfIsCredited() {
        let f = forecaster(balance: "1000.00", asOf: day(2025, 1, 1), income: "2000.00", payday: day(2025, 1, 25))
        // window (Jan 1, Feb 28]: paydays Jan 25 + Feb 25 → +2*2000
        #expect(f.projectedBalance(on: day(2025, 2, 28)) == dec("5000.00"))
    }

    @Test func incomeOnOrBeforeAsOfIsExcluded() {
        let f = forecaster(balance: "1000.00", asOf: day(2025, 1, 26), income: "2000.00", payday: day(2025, 1, 25))
        // Jan 25 is before asOf (already in balance); next payday Feb 25 > target Jan 31
        #expect(f.projectedBalance(on: day(2025, 1, 31)) == dec("1000.00"))
    }

    @Test func incomeAndChargesCombine() {
        let sub = SubscriptionPlan(amount: dec("10.00"), cycle: .monthly, anchorDate: day(2025, 1, 10), status: .active)
        let f = forecaster(balance: "1000.00", asOf: day(2025, 1, 1), income: "500.00", payday: day(2025, 1, 20), [sub])
        // -10 (Jan 10 charge) + 500 (Jan 20 payday) = 1490
        #expect(f.projectedBalance(on: day(2025, 1, 31)) == dec("1490.00"))
    }

    @Test func zeroIncomeOrNilPaydayLeavesProjectionUnchanged() {
        let zero = forecaster(balance: "1000.00", asOf: day(2025, 1, 1), income: "0.00", payday: day(2025, 1, 25))
        #expect(zero.projectedBalance(on: day(2025, 6, 1)) == dec("1000.00"))
        let nilPayday = forecaster(balance: "1000.00", asOf: day(2025, 1, 1), income: "2000.00", payday: nil)
        #expect(nilPayday.projectedBalance(on: day(2025, 6, 1)) == dec("1000.00"))
    }
}
