import Foundation

/// Format version + typed failures for the widget snapshot file. Bump `currentVersion` only when
/// the on-disk shape changes incompatibly; `WidgetSnapshotCodec.decode` refuses anything newer.
public enum WidgetSnapshotFormat {
    public static let currentVersion = 1
}

/// Why a snapshot file could not be read. `malformed` collapses every decoding failure into one case.
public enum WidgetSnapshotError: Error, Equatable {
    case unsupportedVersion(found: Int, supported: Int)
    case malformed
}

/// The app→widget data contract: a faithful, portable mirror of the subscriptions the widget
/// needs to render and to compute upcoming charges. The "only active" rule lives in
/// `UpcomingChargePlanner`, not here (mirrors how `ReminderCoordinator` passes all subs and
/// `ReminderPlanner` filters).
public struct WidgetSnapshot: Codable, Equatable, Sendable {
    /// One subscription's render + scheduling fields.
    public struct Entry: Codable, Equatable, Sendable {
        public var name: String
        public var serviceKey: String?
        public var amount: Decimal
        public var billingCycle: BillingCycle
        public var anchorDate: Date
        public var status: SubscriptionStatus

        public init(name: String, serviceKey: String?, amount: Decimal,
                    billingCycle: BillingCycle, anchorDate: Date, status: SubscriptionStatus) {
            self.name = name
            self.serviceKey = serviceKey
            self.amount = amount
            self.billingCycle = billingCycle
            self.anchorDate = anchorDate
            self.status = status
        }
    }

    public var formatVersion: Int
    public var generatedAt: Date
    public var entries: [Entry]

    public init(formatVersion: Int = WidgetSnapshotFormat.currentVersion,
                generatedAt: Date, entries: [Entry]) {
        self.formatVersion = formatVersion
        self.generatedAt = generatedAt
        self.entries = entries
    }
}
