import Foundation
import SwiftData

/// Versioned schema for Cadence's persistence layer.
///
/// Wrapping V1 in a `VersionedSchema` now (with NO `SchemaMigrationPlan` yet) costs a few
/// lines and gives the first real migration a clean, named anchor. Both models are
/// **CloudKit-legal by construction** so Slice 7 can switch sync on with a one-line config
/// change (see `CadenceStore`):
///   * Every stored property is `Optional` OR has an inline default *in the declaration*
///     (CloudKit must materialize a record from partial, out-of-order sync data).
///   * No `@Attribute(.unique)` anywhere (CloudKit cannot enforce cross-device uniqueness).
///   * Money is `Decimal`; the String-backed enums are stored directly (SwiftData persists
///     them as a native String field — no rawValue column, no transformable).
/// Defaults are deliberate "unset" sentinels (`.distantPast`, `0`, `""`), never `.now`, so a
/// partially-synced row can never masquerade as real data. The convenience `init` always
/// overwrites them.
enum CadenceSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Subscription.self, BalanceAnchor.self]
    }

    @Model
    final class Subscription {
        var name: String = ""
        var amount: Decimal = 0
        var billingCycle: BillingCycle = BillingCycle.monthly
        var anchorDate: Date = Date.distantPast
        var status: SubscriptionStatus = SubscriptionStatus.active
        var category: String = ""
        var serviceKey: String? = nil   // optional => CloudKit-legal; NEVER @Attribute(.unique)

        init(
            name: String,
            amount: Decimal,
            billingCycle: BillingCycle,
            anchorDate: Date,
            status: SubscriptionStatus = .active,
            category: String,
            serviceKey: String? = nil
        ) {
            self.name = name
            self.amount = amount
            self.billingCycle = billingCycle
            self.anchorDate = anchorDate
            self.status = status
            self.category = category
            self.serviceKey = serviceKey
        }
    }

    @Model
    final class BalanceAnchor {
        var balance: Decimal = 0
        var asOfDate: Date = Date.distantPast

        init(balance: Decimal, asOfDate: Date) {
            self.balance = balance
            self.asOfDate = asOfDate
        }
    }
}

/// Stable, call-site-friendly names that stay constant across schema versions.
typealias Subscription = CadenceSchemaV1.Subscription
typealias BalanceAnchor = CadenceSchemaV1.BalanceAnchor
