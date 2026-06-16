@testable import Cadence
import CadenceKit
import Foundation
import Testing

struct RecentChargesTests {
    /// Fixed UTC gregorian calendar so dates are deterministic regardless of machine TZ.
    private var utc: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }

    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        utc.date(from: DateComponents(year: y, month: m, day: d))!
    }

    private func sub(anchor: Date, cycle: BillingCycle, amount: String) -> Subscription {
        Subscription(name: "X", amount: Decimal(string: amount)!, billingCycle: cycle,
                     anchorDate: anchor, category: "Test")
    }

    @Test func monthlyReturnsMostRecentFirstWithinLimit() {
        let s = sub(anchor: date(2025, 1, 15), cycle: .monthly, amount: "9.99")
        let charges = RecentCharges.recent(for: s, asOf: date(2025, 4, 20), calendar: utc, limit: 3)
        #expect(charges.map(\.date) == [date(2025, 4, 15), date(2025, 3, 15), date(2025, 2, 15)])
        #expect(charges.allSatisfy { $0.amount == Decimal(string: "9.99")! })
    }

    @Test func yearlyDerivesAnnualDates() {
        let s = sub(anchor: date(2023, 3, 2), cycle: .yearly, amount: "49.00")
        let charges = RecentCharges.recent(for: s, asOf: date(2025, 6, 1), calendar: utc, limit: 3)
        #expect(charges.map(\.date) == [date(2025, 3, 2), date(2024, 3, 2), date(2023, 3, 2)])
    }

    @Test func emptyWhenAnchorIsInTheFuture() {
        let s = sub(anchor: date(2030, 1, 1), cycle: .monthly, amount: "5.00")
        #expect(RecentCharges.recent(for: s, asOf: date(2025, 1, 1), calendar: utc).isEmpty)
    }

    @Test func respectsLimit() {
        let s = sub(anchor: date(2024, 1, 10), cycle: .monthly, amount: "1.00")
        let charges = RecentCharges.recent(for: s, asOf: date(2025, 1, 10), calendar: utc, limit: 2)
        #expect(charges.count == 2)
        #expect(charges.first?.date == date(2025, 1, 10))
    }
}
