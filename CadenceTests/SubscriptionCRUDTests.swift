import Foundation
import SwiftData
import Testing
@testable import Cadence

struct SubscriptionCRUDTests {
    let container = CadenceStore.inMemory()

    private func dec(_ s: String) -> Decimal { Decimal(string: s)! }

    private var utc: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }
    private func day(_ y: Int, _ m: Int, _ d: Int) -> Date {
        utc.date(from: DateComponents(year: y, month: m, day: d, hour: 12))!
    }

    @Test func allSubscriptionsReturnsInsertedSortedByName() throws {
        let context = ModelContext(container)
        context.insert(Subscription(name: "Spotify", amount: dec("11.97"), billingCycle: .monthly, anchorDate: day(2026, 6, 20), status: .active, category: "Music"))
        context.insert(Subscription(name: "Netflix", amount: dec("9.99"), billingCycle: .monthly, anchorDate: day(2026, 6, 12), status: .active, category: "Entertainment"))

        let all = try context.allSubscriptions()
        #expect(all.map(\.name) == ["Netflix", "Spotify"])
    }

    @Test func deleteRemovesSubscription() throws {
        let context = ModelContext(container)
        let sub = Subscription(name: "Disney+", amount: dec("8.99"), billingCycle: .monthly, anchorDate: day(2026, 6, 1), status: .active, category: "Entertainment")
        context.insert(sub)
        #expect(try context.allSubscriptions().count == 1)

        context.delete(sub)
        #expect(try context.allSubscriptions().isEmpty)
    }

    @Test func activePlansExcludesPausedAndEnded() throws {
        let context = ModelContext(container)
        context.insert(Subscription(name: "Active", amount: dec("10.00"), billingCycle: .monthly, anchorDate: day(2026, 6, 1), status: .active, category: "x"))
        context.insert(Subscription(name: "Paused", amount: dec("20.00"), billingCycle: .monthly, anchorDate: day(2026, 6, 1), status: .paused, category: "x"))
        context.insert(Subscription(name: "Ended", amount: dec("30.00"), billingCycle: .monthly, anchorDate: day(2026, 6, 1), status: .ended, category: "x"))

        let plans = try context.activePlans()
        #expect(plans.count == 1)
        #expect(plans.first?.amount == dec("10.00"))
    }

    @Test func setAnchorCreatesThenUpdatesInPlace() throws {
        let context = ModelContext(container)

        try context.setAnchor(balance: dec("100.00"), asOfDate: day(2026, 6, 1))
        #expect(try context.fetch(FetchDescriptor<BalanceAnchor>()).count == 1)

        // Re-anchoring updates the existing row rather than inserting a second one.
        try context.setAnchor(balance: dec("250.50"), asOfDate: day(2026, 6, 15))
        let anchors = try context.fetch(FetchDescriptor<BalanceAnchor>())
        #expect(anchors.count == 1)

        let current = try #require(try context.currentAnchor())
        #expect(current.balance == dec("250.50"))
        #expect(current.asOfDate == day(2026, 6, 15))
    }

    @Test func currentAnchorIsNilWhenNoneSet() throws {
        let context = ModelContext(container)
        #expect(try context.currentAnchor() == nil)
    }

    /// The payoff: data fetched from the store drives the already-tested Forecaster.
    @Test func forecasterConsumesFetchedActivePlans() throws {
        let context = ModelContext(container)
        context.insert(Subscription(name: "Active", amount: dec("30.00"), billingCycle: .monthly, anchorDate: day(2026, 6, 10), status: .active, category: "x"))
        context.insert(Subscription(name: "Paused", amount: dec("99.00"), billingCycle: .monthly, anchorDate: day(2026, 6, 10), status: .paused, category: "x"))
        try context.setAnchor(balance: dec("100.00"), asOfDate: day(2026, 6, 1))

        let anchor = try #require(try context.currentAnchor())
        let plans = try context.activePlans()
        let forecaster = Forecaster(
            anchorBalance: anchor.balance,
            asOfDate: anchor.asOfDate,
            subscriptions: plans,
            calendar: utc
        )

        // Window (Jun 1, Jun 30]: only the active 30.00 charge lands (Jun 10); paused excluded.
        // 100.00 − 30.00 = 70.00
        #expect(forecaster.projectedBalance(on: day(2026, 6, 30)) == dec("70.00"))
    }
}
