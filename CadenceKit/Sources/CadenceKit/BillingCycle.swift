import Foundation

/// How often a subscription charges.
///
/// `String`-backed + `Codable` + `CaseIterable` so later slices can persist it
/// (SwiftData) and list it in a SwiftUI `Picker`. `Sendable` because it's a pure value.
public enum BillingCycle: String, Codable, CaseIterable, Sendable {
    case monthly
    case yearly

    /// The calendar offset for `n` cycles, used to advance from the anchor date.
    /// Example: `.monthly.components(times: 3)` → `DateComponents(month: 3)`.
    func components(times n: Int) -> DateComponents {
        switch self {
        case .monthly: return DateComponents(month: n)
        case .yearly:  return DateComponents(year: n)
        }
    }
}
