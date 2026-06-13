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

    /// This subscription's cost normalized to a single month (yearly ÷ 12). Exact `Decimal`.
    var normalizedMonthlyAmount: Decimal {
        switch cycle {
        case .monthly: return amount
        case .yearly:  return amount / 12
        }
    }

    /// This subscription's cost normalized to a single year (monthly × 12). Exact `Decimal`.
    var normalizedYearlyAmount: Decimal {
        switch cycle {
        case .monthly: return amount * 12
        case .yearly:  return amount
        }
    }
}
