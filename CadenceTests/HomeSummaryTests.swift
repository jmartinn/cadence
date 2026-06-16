@testable import Cadence
import CadenceKit
import Foundation
import Testing

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

    // MARK: - Existing regression tests (today: renamed to referenceDate:; same date value)

    @Test func paidAmountIncludesOnlyChargesOnOrBeforeToday() {
        let subs = [sub("Netflix", "17.99", day: 4), sub("Figma", "15.00", day: 12)]
        let s = HomeSummary.make(subscriptions: subs, anchor: nil, referenceDate: date(2025, 12, 11), calendar: utc)
        #expect(s.paid == 1)
        #expect(s.total == 2)
        #expect(s.paidAmount == Decimal(string: "17.99")!)   // only Dec 4 ≤ Dec 11
    }

    @Test func clusterNamesAreOrderedByChargeDate() {
        let subs = [sub("Figma", "15.00", day: 12), sub("Netflix", "17.99", day: 4), sub("Spotify", "10.99", day: 8)]
        let s = HomeSummary.make(subscriptions: subs, anchor: nil, referenceDate: date(2025, 12, 11), calendar: utc)
        #expect(s.clusterNames == ["Netflix", "Spotify", "Figma"])
    }

    @Test func projectedIsNilWithoutAnchor() {
        let s = HomeSummary.make(subscriptions: [sub("Netflix", "17.99", day: 4)],
                                 anchor: nil, referenceDate: date(2025, 12, 11), calendar: utc)
        #expect(s.projectedEndOfMonth == nil)
    }

    @Test func projectedUsesAnchorBalanceIncomeAndCharges() {
        let anchor = BalanceAnchor(balance: Decimal(string: "1000.00")!, asOfDate: date(2025, 12, 1),
                                   monthlyIncome: Decimal(string: "500.00")!, incomePayday: date(2025, 12, 20))
        let subs = [sub("Netflix", "17.99", day: 4)]
        let s = HomeSummary.make(subscriptions: subs, anchor: anchor, referenceDate: date(2025, 12, 11), calendar: utc)
        // 1000 + 500 (Dec 20) − 17.99 (Dec 4) = 1482.01
        #expect(s.projectedEndOfMonth == Decimal(string: "1482.01")!)
    }

    @Test func pausedAndEndedSubsAreExcluded() {
        let subs = [sub("A", "10.00", day: 4),
                    sub("B", "20.00", day: 5, status: .paused),
                    sub("C", "30.00", day: 6, status: .ended)]
        let s = HomeSummary.make(subscriptions: subs, anchor: nil, referenceDate: date(2025, 12, 11), calendar: utc)
        #expect(s.total == 1)
        #expect(s.clusterNames == ["A"])
    }

    @Test func renewingIsThisMonthSortedByChargeDate() {
        let subs = [sub("Figma", "15.00", day: 12), sub("Netflix", "17.99", day: 4)]
        let items = HomeSummary.renewing(subscriptions: subs, referenceDate: date(2025, 12, 11), calendar: utc)
        #expect(items.map(\.subscription.name) == ["Netflix", "Figma"])
        #expect(items.first?.chargeDate == date(2025, 12, 4))
    }

    // MARK: - New tests for referenceDate / today split

    /// projectedEndOfMonth targets the END of referenceDate's month, not today's month.
    /// anchor.asOfDate = Jan 1 2026; referenceDate = Feb 2026; today = Jan 15 2026.
    /// Charges after Jan 1 up to end of Feb: Jan 4 + Feb 4 = 2 × 17.99 = 35.98
    /// Projected = 1000 − 35.98 = 964.02.
    /// A wrong impl (using today's month end = Jan 31) would give 1000 − 17.99 = 982.01.
    @Test func futureMonthProjectionTargetsFutureMonthEnd() {
        let anchor = BalanceAnchor(balance: Decimal(string: "1000.00")!, asOfDate: date(2026, 1, 1))
        let subs = [sub("Netflix", "17.99", day: 4)]
        let s = HomeSummary.make(subscriptions: subs, anchor: anchor,
                                 referenceDate: date(2026, 2, 15),
                                 today: date(2026, 1, 15),
                                 calendar: utc)
        #expect(s.projectedEndOfMonth == Decimal(string: "964.02")!)
    }

    /// paidAmount filters charges in referenceDate's month by <= now, not by <= referenceDate.
    /// Netflix charges Feb 4 (in referenceDate=Feb 2026's month). Feb 4 > Jan 15 (today) → paidAmount = 0.
    /// A wrong impl using referenceDate (Feb 15) as cutoff would yield 17.99.
    @Test func paidAmountTracksNowNotReferenceDate() {
        let subs = [sub("Netflix", "17.99", day: 4)]
        let s = HomeSummary.make(subscriptions: subs, anchor: nil,
                                 referenceDate: date(2026, 2, 15),
                                 today: date(2026, 1, 15),
                                 calendar: utc)
        #expect(s.paidAmount == 0)
    }

    /// clusterNames reflects referenceDate's month, not today's month.
    /// AnnualFeb is a yearly sub anchored Feb 3 2025; it charges Feb 3 2026 but has no Jan charge.
    /// Netflix charges Feb 10 2026 (Dec 10 + 2 months). With referenceDate = Feb 2026:
    ///   clusterNames = ["AnnualFeb", "Netflix"] (sorted Feb 3 < Feb 10).
    /// A wrong impl using today (Jan 2026) would give only ["Netflix"] (AnnualFeb has no Jan charge).
    @Test func clusterNamesKeyedOffReferenceDate() {
        let annualFeb = Subscription(name: "AnnualFeb", amount: Decimal(string: "100.00")!,
                                     billingCycle: .yearly, anchorDate: date(2025, 2, 3),
                                     status: .active, category: "Test")
        let subs = [sub("Netflix", "17.99", day: 10), annualFeb]
        let s = HomeSummary.make(subscriptions: subs, anchor: nil,
                                 referenceDate: date(2026, 2, 15),
                                 today: date(2026, 1, 15),
                                 calendar: utc)
        #expect(s.clusterNames == ["AnnualFeb", "Netflix"])
    }

    /// renewing(referenceDate:) returns subscriptions with a charge in referenceDate's month.
    /// With referenceDate = Feb 2026, chargeDate is Feb 4 — not Jan 4.
    @Test func renewingKeyedOffReferenceDate() {
        let subs = [sub("Figma", "15.00", day: 12), sub("Netflix", "17.99", day: 4)]
        let items = HomeSummary.renewing(subscriptions: subs,
                                         referenceDate: date(2026, 2, 15),
                                         calendar: utc)
        #expect(items.map(\.subscription.name) == ["Netflix", "Figma"])
        #expect(items.first?.chargeDate == date(2026, 2, 4))
    }
}
