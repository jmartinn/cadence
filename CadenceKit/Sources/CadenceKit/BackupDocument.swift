import Foundation

/// Format version + typed failures for the backup file. Bump `currentVersion` only when the
/// on-disk shape changes incompatibly; `BackupCodec.decode` refuses anything newer.
public enum BackupFormat {
    public static let currentVersion = 1
}

/// Why a backup file could not be read. `malformed` collapses every decoding failure (bad
/// JSON, missing/extra fields, wrong types) into one user-facing case.
public enum BackupError: Error, Equatable {
    case unsupportedVersion(found: Int, supported: Int)
    case malformed
}

/// A single balance anchor, portable form of `BalanceAnchor`.
public struct BackupAnchor: Codable, Equatable, Sendable {
    public var balance: Decimal
    public var asOfDate: Date
    public var monthlyIncome: Decimal
    public var incomePayday: Date

    public init(balance: Decimal, asOfDate: Date, monthlyIncome: Decimal, incomePayday: Date) {
        self.balance = balance
        self.asOfDate = asOfDate
        self.monthlyIncome = monthlyIncome
        self.incomePayday = incomePayday
    }
}

/// Portable form of a `Subscription`. `id` is **file-local** — generated fresh at export and
/// used only so `parentID` can express the add-on link without leaning on `persistentModelID`
/// (which is not portable across stores/devices).
public struct BackupSubscription: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var name: String
    public var amount: Decimal
    public var billingCycle: BillingCycle
    public var anchorDate: Date
    public var status: SubscriptionStatus
    public var category: String
    public var serviceKey: String?
    public var paymentBrand: String?
    public var paymentLast4: String?
    public var parentID: UUID?

    public init(id: UUID, name: String, amount: Decimal, billingCycle: BillingCycle,
                anchorDate: Date, status: SubscriptionStatus, category: String,
                serviceKey: String? = nil, paymentBrand: String? = nil,
                paymentLast4: String? = nil, parentID: UUID? = nil) {
        self.id = id
        self.name = name
        self.amount = amount
        self.billingCycle = billingCycle
        self.anchorDate = anchorDate
        self.status = status
        self.category = category
        self.serviceKey = serviceKey
        self.paymentBrand = paymentBrand
        self.paymentLast4 = paymentLast4
        self.parentID = parentID
    }
}

/// The whole backup: a versioned envelope around the user's portable data.
public struct BackupDocument: Codable, Equatable, Sendable {
    public var formatVersion: Int
    public var exportedAt: Date
    public var appVersion: String?
    public var subscriptions: [BackupSubscription]
    public var anchor: BackupAnchor?

    public init(formatVersion: Int = BackupFormat.currentVersion, exportedAt: Date,
                appVersion: String?, subscriptions: [BackupSubscription], anchor: BackupAnchor?) {
        self.formatVersion = formatVersion
        self.exportedAt = exportedAt
        self.appVersion = appVersion
        self.subscriptions = subscriptions
        self.anchor = anchor
    }
}
