import Foundation
import Observation

/// Shared tab selection so one tab can switch to another (e.g. Home's "See all" → Subscriptions).
/// Lives in the environment, set by `RootTabView`.
@Observable
final class TabRouter {
    var selection: Int = TabRouter.home   // Home is the forecast dashboard → the natural landing tab

    static let home = 0
    static let subscriptions = 1
    static let transactions = 2
}
