import Foundation

/// A subscription's forecast-relevant data as a pure value.
///
/// Deliberately SwiftData-free: the Slice 3 `@Model Subscription` maps *into* this
/// (`var plan: SubscriptionPlan`) so `Forecaster` can stay unit-testable with no database.
public struct SubscriptionPlan: Sendable {
    public var amount: Decimal          // money = Decimal, never Double; always positive
    public var cycle: BillingCycle
    public var anchorDate: Date         // reference charge date; occurrences derive from this + cycle
    public var status: SubscriptionStatus

    public init(amount: Decimal, cycle: BillingCycle, anchorDate: Date, status: SubscriptionStatus) {
        self.amount = amount
        self.cycle = cycle
        self.anchorDate = anchorDate
        self.status = status
    }

    /// This subscription's cost normalized to a single month (yearly ÷ 12). Exact `Decimal`.
    public var normalizedMonthlyAmount: Decimal {
        switch cycle {
        case .monthly: return amount
        case .yearly:  return amount / 12
        }
    }

    /// This subscription's cost normalized to a single year (monthly × 12). Exact `Decimal`.
    public var normalizedYearlyAmount: Decimal {
        switch cycle {
        case .monthly: return amount * 12
        case .yearly:  return amount
        }
    }
}
