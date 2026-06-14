import Foundation
import Observation

/// Shared tab selection so one tab can switch to another (e.g. Home's "See all" → Subscriptions).
/// Lives in the environment, set by `RootTabView`.
@Observable
final class TabRouter {
    var selection: Int = TabRouter.subscriptions

    static let home = 0
    static let subscriptions = 1
    static let transactions = 2
}
