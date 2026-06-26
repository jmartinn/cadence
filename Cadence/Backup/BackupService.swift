import CadenceKit
import Foundation
import SwiftData

/// The single SwiftData boundary for backup: maps `@Model` ↔ portable DTOs and performs the
/// destructive replace-all restore. All serialization lives in `BackupCodec` (CadenceKit).
enum BackupService {
    /// Snapshot everything in the store as a portable document. Each subscription gets a fresh
    /// file-local UUID; the add-on link is carried as `parentID` against those ids (never the
    /// non-portable `persistentModelID`).
    static func export(from context: ModelContext, exportedAt: Date = .now,
                       appVersion: String? = AppInfo.current) throws -> BackupDocument {
        let subscriptions = try context.fetch(FetchDescriptor<Subscription>())

        var fileID: [PersistentIdentifier: UUID] = [:]
        for sub in subscriptions {
            fileID[sub.persistentModelID] = UUID()
        }

        let dtos = subscriptions.map { sub in
            BackupSubscription(
                id: fileID[sub.persistentModelID]!,
                name: sub.name,
                amount: sub.amount,
                billingCycle: sub.billingCycle,
                anchorDate: sub.anchorDate,
                status: sub.status,
                category: sub.category,
                serviceKey: sub.serviceKey,
                paymentBrand: sub.paymentBrand,
                paymentLast4: sub.paymentLast4,
                parentID: sub.parent.flatMap { fileID[$0.persistentModelID] }
            )
        }

        let anchor = try context.currentAnchor().map { a in
            BackupAnchor(balance: a.balance, asOfDate: a.asOfDate,
                         monthlyIncome: a.monthlyIncome, incomePayday: a.incomePayday)
        }

        return BackupDocument(exportedAt: exportedAt, appVersion: appVersion,
                              subscriptions: dtos, anchor: anchor)
    }
}
