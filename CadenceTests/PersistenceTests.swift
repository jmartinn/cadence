import Foundation
import SwiftData
import Testing
@testable import Cadence

/// Round-trip tests for the SwiftData models through a hermetic in-memory store.
/// A fresh container per test (new struct instance per `@Test`) keeps tests isolated.
struct PersistenceTests {
    // Held as a stored property so the container outlives each test method
    // (a ModelContext alone is not enough to keep the store alive).
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
}
