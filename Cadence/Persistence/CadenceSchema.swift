import CadenceKit
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
        var serviceKey: String?   // optional => CloudKit-legal; NEVER @Attribute(.unique)
        var paymentBrand: String?  // display-only, e.g. "Visa"; never enters the forecast
        var paymentLast4: String?  // display-only, e.g. "4821"

        init(
            name: String,
            amount: Decimal,
            billingCycle: BillingCycle,
            anchorDate: Date,
            status: SubscriptionStatus = .active,
            category: String,
            serviceKey: String? = nil,
            paymentBrand: String? = nil,
            paymentLast4: String? = nil
        ) {
            self.name = name
            self.amount = amount
            self.billingCycle = billingCycle
            self.anchorDate = anchorDate
            self.status = status
            self.category = category
            self.serviceKey = serviceKey
            self.paymentBrand = paymentBrand
            self.paymentLast4 = paymentLast4
        }

        /// Bridge to the pure, database-agnostic domain value type that `Forecaster`
        /// consumes. Computed => not persisted => zero CloudKit cost (no `@Transient` needed).
        /// Read this on the actor that owns the model (main actor in Slice 3); the returned
        /// `SubscriptionPlan` is a `Sendable` snapshot that is safe to hand off anywhere.
        var plan: SubscriptionPlan {
            SubscriptionPlan(
                amount: amount,
                cycle: billingCycle,
                anchorDate: anchorDate,
                status: status
            )
        }
    }

    @Model
    final class BalanceAnchor {
        var balance: Decimal = 0
        var asOfDate: Date = Date.distantPast
        var monthlyIncome: Decimal = 0           // recurring monthly income; 0 = none
        var incomePayday: Date = Date.distantPast // reference payday; .distantPast = no income

        init(
            balance: Decimal,
            asOfDate: Date,
            monthlyIncome: Decimal = 0,
            incomePayday: Date = .distantPast
        ) {
            self.balance = balance
            self.asOfDate = asOfDate
            self.monthlyIncome = monthlyIncome
            self.incomePayday = incomePayday
        }
    }
}

/// V2 — adds the display-only self-referential add-on relationship. Additive & optional, so
/// the V1→V2 migration is lightweight (see `CadenceMigrationPlan`). Still CloudKit-legal:
/// the relationship is optional/defaulted, declares its inverse, and there is no `.unique`.
enum CadenceSchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)

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
        var serviceKey: String?
        var paymentBrand: String?
        var paymentLast4: String?

        /// This subscription's add-ons (e.g. Amazon Prime → its channels). Defaulted `[]` =>
        /// CloudKit-legal. `.nullify` => deleting the parent orphans add-ons into standalone
        /// subs; it never cascade-deletes a sub that is still billing the user.
        @Relationship(deleteRule: .nullify, inverse: \Subscription.parent)
        var addOns: [Subscription] = []

        /// nil => standalone; non-nil => this subscription IS an add-on of `parent`.
        var parent: Subscription?

        init(
            name: String,
            amount: Decimal,
            billingCycle: BillingCycle,
            anchorDate: Date,
            status: SubscriptionStatus = .active,
            category: String,
            serviceKey: String? = nil,
            paymentBrand: String? = nil,
            paymentLast4: String? = nil
        ) {
            self.name = name
            self.amount = amount
            self.billingCycle = billingCycle
            self.anchorDate = anchorDate
            self.status = status
            self.category = category
            self.serviceKey = serviceKey
            self.paymentBrand = paymentBrand
            self.paymentLast4 = paymentLast4
        }

        var plan: SubscriptionPlan {
            SubscriptionPlan(
                amount: amount,
                cycle: billingCycle,
                anchorDate: anchorDate,
                status: status
            )
        }
    }

    @Model
    final class BalanceAnchor {
        var balance: Decimal = 0
        var asOfDate: Date = Date.distantPast
        var monthlyIncome: Decimal = 0
        var incomePayday: Date = Date.distantPast

        init(
            balance: Decimal,
            asOfDate: Date,
            monthlyIncome: Decimal = 0,
            incomePayday: Date = .distantPast
        ) {
            self.balance = balance
            self.asOfDate = asOfDate
            self.monthlyIncome = monthlyIncome
            self.incomePayday = incomePayday
        }
    }
}

/// Stable, call-site-friendly names that stay constant across schema versions.
typealias Subscription = CadenceSchemaV2.Subscription
typealias BalanceAnchor = CadenceSchemaV2.BalanceAnchor
