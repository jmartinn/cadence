import Foundation

/// A subscription's forecast-relevant data as a pure value.
///
/// Deliberately SwiftData-free: the Slice 3 `@Model Subscription` maps *into* this
/// (`var plan: SubscriptionPlan`) so `Forecaster` can stay unit-testable with no database.
struct SubscriptionPlan: Sendable {
    var amount: Decimal          // money = Decimal, never Double; always positive
    var cycle: BillingCycle
    var anchorDate: Date         // reference charge date; occurrences derive from this + cycle
    var status: SubscriptionStatus
}
