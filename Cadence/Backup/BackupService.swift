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

    /// A stable, human-readable filename for an exported backup, e.g.
    /// `Cadence-Backup-2026-06-26.json`. Fixed `en_US_POSIX` + UTC so the stamp never shifts
    /// with the user's locale or timezone.
    static func suggestedFilename(for date: Date = .now) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyy-MM-dd"
        return "Cadence-Backup-\(formatter.string(from: date)).json"
    }

    /// Replace ALL data with the document's contents. Destructive — callers must confirm first.
    /// Deletes every subscription + the anchor, then re-creates rows in two passes (create all,
    /// then wire `parent` from `parentID`) so add-on links survive, and restores the anchor.
    static func restore(_ document: BackupDocument, into context: ModelContext) throws {
        for sub in try context.fetch(FetchDescriptor<Subscription>()) {
            context.delete(sub)
        }
        if let anchor = try context.currentAnchor() {
            context.delete(anchor)
        }

        var byFileID: [UUID: Subscription] = [:]
        for dto in document.subscriptions {
            let sub = Subscription(
                name: dto.name, amount: dto.amount, billingCycle: dto.billingCycle,
                anchorDate: dto.anchorDate, status: dto.status, category: dto.category,
                serviceKey: dto.serviceKey, paymentBrand: dto.paymentBrand,
                paymentLast4: dto.paymentLast4
            )
            context.insert(sub)
            byFileID[dto.id] = sub
        }
        for dto in document.subscriptions {
            guard let parentID = dto.parentID,
                  let child = byFileID[dto.id],
                  let parent = byFileID[parentID] else { continue }
            child.parent = parent
        }

        if let anchor = document.anchor {
            try context.setAnchor(balance: anchor.balance, asOfDate: anchor.asOfDate,
                                  monthlyIncome: anchor.monthlyIncome, incomePayday: anchor.incomePayday)
        }

        try context.save()
    }
}
