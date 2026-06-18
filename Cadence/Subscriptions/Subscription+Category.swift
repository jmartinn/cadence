import CadenceKit

extension Subscription {
    /// Type-safe read of the stored free-form `category` string. Unknown or blank values coerce
    /// to `.other`, so a legacy hand-typed category never crashes the UI; it degrades gracefully
    /// until the subscription is next saved (which normalizes `category` to a valid raw value).
    var categoryKind: SubscriptionCategory {
        SubscriptionCategory(rawValue: category) ?? .other
    }
}
