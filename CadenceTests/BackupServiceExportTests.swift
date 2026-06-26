@testable import Cadence
import CadenceKit
import Foundation
import SwiftData
import Testing

struct BackupServiceExportTests {
    let container = CadenceStore.inMemory()
    let stamp = Date(timeIntervalSince1970: 1_700_000_000)

    @Test func exportMapsEveryField() throws {
        let context = ModelContext(container)
        context.insert(Subscription(
            name: "Netflix", amount: Decimal(string: "9.99")!, billingCycle: .monthly,
            anchorDate: Date(timeIntervalSince1970: 1_000_000), status: .active,
            category: "Entertainment", serviceKey: "netflix",
            paymentBrand: "Visa", paymentLast4: "4821"
        ))
        try context.setAnchor(balance: Decimal(string: "1025.06")!,
                              asOfDate: Date(timeIntervalSince1970: 2_000_000),
                              monthlyIncome: Decimal(string: "2000.00")!,
                              incomePayday: Date(timeIntervalSince1970: 1_500_000))
        try context.save()

        let doc = try BackupService.export(from: context, exportedAt: stamp, appVersion: "1.0")
        #expect(doc.formatVersion == BackupFormat.currentVersion)
        #expect(doc.exportedAt == stamp)
        #expect(doc.appVersion == "1.0")
        #expect(doc.subscriptions.count == 1)
        let s = try #require(doc.subscriptions.first)
        #expect(s.name == "Netflix")
        #expect(s.amount == Decimal(string: "9.99")!)
        #expect(s.billingCycle == .monthly)
        #expect(s.anchorDate == Date(timeIntervalSince1970: 1_000_000))
        #expect(s.status == .active)
        #expect(s.category == "Entertainment")
        #expect(s.serviceKey == "netflix")
        #expect(s.paymentBrand == "Visa")
        #expect(s.paymentLast4 == "4821")
        #expect(s.parentID == nil)
        #expect(doc.anchor?.balance == Decimal(string: "1025.06")!)
        #expect(doc.anchor?.monthlyIncome == Decimal(string: "2000.00")!)
        #expect(doc.anchor?.incomePayday == Date(timeIntervalSince1970: 1_500_000))
    }

    @Test func exportExpressesAddOnTreeViaParentID() throws {
        let context = ModelContext(container)
        let prime = Subscription(name: "Amazon Prime", amount: Decimal(string: "8.99")!,
                                 billingCycle: .monthly, anchorDate: .distantPast, category: "Shopping")
        let paramount = Subscription(name: "Paramount+", amount: Decimal(string: "7.99")!,
                                     billingCycle: .monthly, anchorDate: .distantPast, category: "Entertainment")
        context.insert(prime); context.insert(paramount)
        paramount.parent = prime
        try context.save()

        let doc = try BackupService.export(from: context, exportedAt: stamp, appVersion: nil)
        let primeDTO = try #require(doc.subscriptions.first { $0.name == "Amazon Prime" })
        let paramountDTO = try #require(doc.subscriptions.first { $0.name == "Paramount+" })
        #expect(primeDTO.parentID == nil)
        #expect(paramountDTO.parentID == primeDTO.id)
        #expect(primeDTO.id != paramountDTO.id) // distinct file-local ids
    }

    @Test func exportHasNilAnchorWhenNoneSet() throws {
        let context = ModelContext(container)
        let doc = try BackupService.export(from: context, exportedAt: stamp, appVersion: nil)
        #expect(doc.subscriptions.isEmpty)
        #expect(doc.anchor == nil)
    }
}
