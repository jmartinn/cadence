import Foundation

/// Minimal per-subscription snapshot the planner needs. `SubscriptionPlan` carries the
/// amount/cycle/anchor/status used for the math, but no display name or stable id, so the app
/// builds this from each `@Model` row. Keeps CadenceKit database-agnostic.
public struct ReminderTarget: Sendable {
    /// Stable identity used in the notification id (e.g. serviceKey ?? name).
    public let id: String
    public let name: String
    public let plan: SubscriptionPlan

    public init(id: String, name: String, plan: SubscriptionPlan) {
        self.id = id
        self.name = name
        self.plan = plan
    }
}
