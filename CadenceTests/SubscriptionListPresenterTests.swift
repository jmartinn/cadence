@testable import Cadence
import CadenceKit
import Foundation
import SwiftData
import Testing

struct SubscriptionListPresenterTests {
    let container: ModelContainer

    init() {
        container = CadenceStore.inMemory()
    }

    /// Fixed UTC calendar so schedule math is timezone-independent.
    private var utc: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }

    /// A pinned reference date: 2026-06-14 in UTC.
    private var today: Date {
        utc.date(from: DateComponents(year: 2026, month: 6, day: 14))!
    }

    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        utc.date(from: DateComponents(year: y, month: m, day: d))!
    }

    /// Insert a subscription into a fresh context and return it.
    @discardableResult
    private func makeSub(
        _ name: String,
        _ amount: String,
        _ cycle: BillingCycle,
        anchor: Date,
        in context: ModelContext
    ) -> Subscription {
        let sub = Subscription(
            name: name,
            amount: Decimal(string: amount)!,
            billingCycle: cycle,
            anchorDate: anchor,
            status: .active,
            category: "Test"
        )
        context.insert(sub)
        return sub
    }

    @Test func nameSortIsAlphabetical() {
        let context = ModelContext(container)
        makeSub("Spotify", "10.99", .monthly, anchor: date(2026, 1, 8), in: context)
        makeSub("Amazon Prime", "49.00", .yearly, anchor: date(2025, 3, 2), in: context)
        makeSub("netflix", "17.99", .monthly, anchor: date(2025, 12, 4), in: context)

        let subs = try! context.fetch(FetchDescriptor<Subscription>())
        let sorted = SubscriptionListPresenter.sorted(subs, by: .name, today: today, calendar: utc)

        #expect(sorted.map(\.name) == ["Amazon Prime", "netflix", "Spotify"])
    }

    @Test func priceSortIsHighestNormalizedMonthlyFirst() {
        let context = ModelContext(container)
        // Amazon yearly 49.00 -> normalized monthly ≈ 4.083, between Spotify (10.99) and iCloud (2.99).
        makeSub("Spotify", "10.99", .monthly, anchor: date(2026, 1, 8), in: context)
        makeSub("Amazon Prime", "49.00", .yearly, anchor: date(2025, 3, 2), in: context)
        makeSub("iCloud+", "2.99", .monthly, anchor: date(2026, 1, 1), in: context)

        let subs = try! context.fetch(FetchDescriptor<Subscription>())
        let sorted = SubscriptionListPresenter.sorted(subs, by: .price, today: today, calendar: utc)

        #expect(sorted.map(\.name) == ["Spotify", "Amazon Prime", "iCloud+"])
    }

    @Test func nextChargeSortIsSoonestFirst() {
        let context = ModelContext(container)
        // today = 2026-06-14. Monthly anchors -> next charge after today:
        //  day 20 -> 2026-06-20 ; day 25 -> 2026-06-25 ; day 8 -> 2026-07-08 (06-08 already past).
        makeSub("Later", "5.00", .monthly, anchor: date(2026, 1, 8), in: context)   // 2026-07-08
        makeSub("Soonest", "5.00", .monthly, anchor: date(2026, 1, 20), in: context) // 2026-06-20
        makeSub("Middle", "5.00", .monthly, anchor: date(2026, 1, 25), in: context)  // 2026-06-25

        let subs = try! context.fetch(FetchDescriptor<Subscription>())
        let sorted = SubscriptionListPresenter.sorted(subs, by: .nextCharge, today: today, calendar: utc)

        #expect(sorted.map(\.name) == ["Soonest", "Middle", "Later"])
    }

    @Test func nextChargeComputesMonthlyAndYearly() {
        let context = ModelContext(container)
        let monthly = makeSub("M", "1.00", .monthly, anchor: date(2026, 1, 4), in: context)
        let yearly = makeSub("Y", "1.00", .yearly, anchor: date(2025, 3, 2), in: context)

        let nextMonthly = SubscriptionListPresenter.nextCharge(for: monthly, after: today, calendar: utc)
        let nextYearly = SubscriptionListPresenter.nextCharge(for: yearly, after: today, calendar: utc)

        #expect(nextMonthly == date(2026, 7, 4))
        #expect(nextYearly == date(2027, 3, 2))
    }

    @Test func emptyInputReturnsEmptyForEverySort() {
        for sort in SubscriptionSort.allCases {
            let result = SubscriptionListPresenter.sorted([], by: sort, today: today, calendar: utc)
            #expect(result.isEmpty)
        }
    }
}
