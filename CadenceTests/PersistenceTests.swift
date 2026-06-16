@testable import Cadence
import Foundation
import SwiftData
import Testing

/// Round-trip tests for the SwiftData models through a hermetic in-memory store.
/// A fresh container per test (new struct instance per `@Test`) keeps tests isolated.
struct PersistenceTests {
    /// Held as a stored property so the container outlives each test method
    /// (a ModelContext alone is not enough to keep the store alive).
    let container = CadenceStore.inMemory()

    @Test func subscriptionRoundTripsAllFields() throws {
        let context = ModelContext(container)
        let sub = Subscription(
            name: "Netflix",
            amount: Decimal(string: "9.99")!,
            billingCycle: .monthly,
            anchorDate: Date(timeIntervalSince1970: 1_000_000),
            status: .active,
            category: "Entertainment",
            serviceKey: "netflix"
        )
        context.insert(sub)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Subscription>())
        #expect(fetched.count == 1)
        let got = try #require(fetched.first)
        #expect(got.name == "Netflix")
        #expect(got.amount == Decimal(string: "9.99")!)
        #expect(got.billingCycle == .monthly)
        #expect(got.anchorDate == Date(timeIntervalSince1970: 1_000_000))
        #expect(got.status == .active)
        #expect(got.category == "Entertainment")
        #expect(got.serviceKey == "netflix")
    }

    @Test func subscriptionAllowsNilServiceKey() throws {
        let context = ModelContext(container)
        context.insert(Subscription(
            name: "Self-hosted",
            amount: Decimal(string: "0.00")!,
            billingCycle: .yearly,
            anchorDate: Date(timeIntervalSince1970: 0),
            status: .active,
            category: "Utilities"
        ))
        try context.save()

        let got = try #require(try context.fetch(FetchDescriptor<Subscription>()).first)
        #expect(got.serviceKey == nil)
        #expect(got.billingCycle == .yearly)
    }

    @Test func balanceAnchorRoundTrips() throws {
        let context = ModelContext(container)
        context.insert(BalanceAnchor(
            balance: Decimal(string: "1087.02")!,
            asOfDate: Date(timeIntervalSince1970: 2_000_000)
        ))
        try context.save()

        let got = try #require(try context.fetch(FetchDescriptor<BalanceAnchor>()).first)
        #expect(got.balance == Decimal(string: "1087.02")!)
        #expect(got.asOfDate == Date(timeIntervalSince1970: 2_000_000))
    }

    @Test func balanceAnchorRoundTripsIncomeFields() throws {
        let context = ModelContext(container)
        context.insert(BalanceAnchor(
            balance: Decimal(string: "1000.00")!,
            asOfDate: Date(timeIntervalSince1970: 1_000),
            monthlyIncome: Decimal(string: "2000.00")!,
            incomePayday: Date(timeIntervalSince1970: 2_000)
        ))
        try context.save()

        let got = try #require(try context.fetch(FetchDescriptor<BalanceAnchor>()).first)
        #expect(got.monthlyIncome == Decimal(string: "2000.00")!)
        #expect(got.incomePayday == Date(timeIntervalSince1970: 2_000))
    }

    @Test func balanceAnchorIncomeDefaultsToZeroAndDistantPast() throws {
        let context = ModelContext(container)
        context.insert(BalanceAnchor(balance: 5, asOfDate: Date(timeIntervalSince1970: 0)))
        try context.save()
        let got = try #require(try context.fetch(FetchDescriptor<BalanceAnchor>()).first)
        #expect(got.monthlyIncome == 0)
        #expect(got.incomePayday == .distantPast)
    }

    @Test func setAnchorWritesIncomeFieldsAndUpsertsInPlace() throws {
        let context = ModelContext(container)
        try context.setAnchor(balance: Decimal(string: "100.00")!,
                              asOfDate: Date(timeIntervalSince1970: 10),
                              monthlyIncome: Decimal(string: "300.00")!,
                              incomePayday: Date(timeIntervalSince1970: 20))
        try context.setAnchor(balance: Decimal(string: "150.00")!,
                              asOfDate: Date(timeIntervalSince1970: 30))   // re-anchor, income omitted

        let all = try context.fetch(FetchDescriptor<BalanceAnchor>())
        #expect(all.count == 1)                                  // upsert, not insert
        let got = try #require(all.first)
        #expect(got.balance == Decimal(string: "150.00")!)
        #expect(got.monthlyIncome == 0)                          // omitted → default 0
        #expect(got.incomePayday == .distantPast)
    }
}
