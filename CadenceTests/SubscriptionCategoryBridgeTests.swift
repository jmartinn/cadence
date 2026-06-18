@testable import Cadence
import CadenceKit
import Foundation
import Testing

/// Proves the read-boundary coercion from the stored free-form `category` string to the closed
/// `SubscriptionCategory` set: known Title-Case strings map to their case; unknown/blank → `.other`.
struct SubscriptionCategoryBridgeTests {
    private func sub(category: String) -> Subscription {
        Subscription(
            name: "X", amount: Decimal(string: "1.00")!, billingCycle: .monthly,
            anchorDate: .distantPast, category: category
        )
    }

    @Test func knownStringResolvesToCase() {
        #expect(sub(category: "Entertainment").categoryKind == .entertainment)
        #expect(sub(category: "Developer Tools").categoryKind == .developerTools)
    }

    @Test func unknownStringResolvesToOther() {
        #expect(sub(category: "Streaming").categoryKind == .other)
    }

    @Test func blankStringResolvesToOther() {
        #expect(sub(category: "").categoryKind == .other)
    }
}
