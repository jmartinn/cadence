import Testing
import Foundation
@testable import Cadence

struct HomeSummaryTests {
    private var utc: Calendar {
        var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(identifier: "UTC")!; return c
    }
    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        utc.date(from: DateComponents(year: y, month: m, day: d))!
    }
    private func sub(_ name: String, _ amount: String, day: Int,
                     status: SubscriptionStatus = .active, card: Bool = false) -> Subscription {
        Subscription(name: name, amount: Decimal(string: amount)!, billingCycle: .monthly,
                     anchorDate: date(2025, 12, day), status: status, category: "Test",
                     paymentBrand: card ? "Visa" : nil, paymentLast4: card ? "4821" : nil)
    }

    @Test func paidAmountIncludesOnlyChargesOnOrBeforeToday() {
        let subs = [sub("Netflix", "17.99", day: 4), sub("Figma", "15.00", day: 12)]
        let s = HomeSummary.make(subscriptions: subs, anchor: nil, today: date(2025, 12, 11), calendar: utc)
        #expect(s.paid == 1)
        #expect(s.total == 2)
        #expect(s.paidAmount == Decimal(string: "17.99")!)   // only Dec 4 ≤ Dec 11
    }

    @Test func clusterNamesAreOrderedByChargeDate() {
        let subs = [sub("Figma", "15.00", day: 12), sub("Netflix", "17.99", day: 4), sub("Spotify", "10.99", day: 8)]
        let s = HomeSummary.make(subscriptions: subs, anchor: nil, today: date(2025, 12, 11), calendar: utc)
        #expect(s.clusterNames == ["Netflix", "Spotify", "Figma"])
    }

    @Test func projectedIsNilWithoutAnchor() {
        let s = HomeSummary.make(subscriptions: [sub("Netflix", "17.99", day: 4)],
                                 anchor: nil, today: date(2025, 12, 11), calendar: utc)
        #expect(s.projectedEndOfMonth == nil)
    }

    @Test func projectedUsesAnchorBalanceIncomeAndCharges() {
        let anchor = BalanceAnchor(balance: Decimal(string: "1000.00")!, asOfDate: date(2025, 12, 1),
                                   monthlyIncome: Decimal(string: "500.00")!, incomePayday: date(2025, 12, 20))
        let subs = [sub("Netflix", "17.99", day: 4)]
        let s = HomeSummary.make(subscriptions: subs, anchor: anchor, today: date(2025, 12, 11), calendar: utc)
        // 1000 + 500 (Dec 20) − 17.99 (Dec 4) = 1482.01
        #expect(s.projectedEndOfMonth == Decimal(string: "1482.01")!)
    }

    @Test func pausedAndEndedSubsAreExcluded() {
        let subs = [sub("A", "10.00", day: 4),
                    sub("B", "20.00", day: 5, status: .paused),
                    sub("C", "30.00", day: 6, status: .ended)]
        let s = HomeSummary.make(subscriptions: subs, anchor: nil, today: date(2025, 12, 11), calendar: utc)
        #expect(s.total == 1)
        #expect(s.clusterNames == ["A"])
    }

    @Test func renewingIsThisMonthSortedByChargeDate() {
        let subs = [sub("Figma", "15.00", day: 12), sub("Netflix", "17.99", day: 4)]
        let items = HomeSummary.renewing(subscriptions: subs, today: date(2025, 12, 11), calendar: utc)
        #expect(items.map(\.subscription.name) == ["Netflix", "Figma"])
        #expect(items.first?.chargeDate == date(2025, 12, 4))
    }
}
