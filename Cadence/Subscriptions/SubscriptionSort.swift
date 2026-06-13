import Foundation

/// The user-selectable orderings for the subscriptions list.
/// `Identifiable` so it can drive a `ForEach` of sort pills.
enum SubscriptionSort: String, CaseIterable, Identifiable {
    case nextCharge
    case price
    case name

    var id: Self { self }

    /// Human label shown on the sort pill.
    var title: String {
        switch self {
        case .nextCharge: return "Next charge"
        case .price: return "Price"
        case .name: return "Name"
        }
    }
}
