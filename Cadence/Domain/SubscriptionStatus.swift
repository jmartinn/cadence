import Foundation

/// Lifecycle of a subscription.
///
/// `String`-backed + `Codable` + `CaseIterable` so the SwiftData `@Model` (Slice 3)
/// can persist it and a SwiftUI `Picker` can list it. Only `.active` subscriptions
/// affect the forecast; `.paused`/`.ended` contribute nothing.
enum SubscriptionStatus: String, Codable, CaseIterable, Sendable {
    case active
    case paused
    case ended
}
