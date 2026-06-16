@testable import Cadence
import Foundation
import SwiftData
import Testing

/// Proves the one-directional `@Model -> value type` bridge maps every forecast-relevant field.
struct SubscriptionBridgeTests {
    let container = CadenceStore.inMemory()

    private func dec(_ s: String) -> Decimal { Decimal(string: s)! }

    @Test func planMirrorsStoredFields() throws {
        let context = ModelContext(container)
        let anchor = Date(timeIntervalSince1970: 1_700_000_000)
        context.insert(Subscription(
            name: "Spotify",
            amount: dec("11.97"),
            billingCycle: .monthly,
            anchorDate: anchor,
            status: .paused,
            category: "Music"
        ))

        let got = try #require(try context.fetch(FetchDescriptor<Subscription>()).first)
        let plan = got.plan

        #expect(plan.amount == dec("11.97"))
        #expect(plan.cycle == .monthly)
        #expect(plan.anchorDate == anchor)
        #expect(plan.status == .paused)
    }

    /// Guards the cycle field specifically for `.yearly`, so a monthly-only mis-mapping
    /// in `Subscription.plan` can't slip past a test that only ever exercised `.monthly`.
    @Test func planMirrorsYearlyCycle() throws {
        let context = ModelContext(container)
        context.insert(Subscription(
            name: "Amazon Prime",
            amount: dec("49.00"),
            billingCycle: .yearly,
            anchorDate: Date(timeIntervalSince1970: 1_700_000_000),
            status: .active,
            category: "Shopping"
        ))

        let got = try #require(try context.fetch(FetchDescriptor<Subscription>()).first)
        #expect(got.plan.cycle == .yearly)
    }
}
