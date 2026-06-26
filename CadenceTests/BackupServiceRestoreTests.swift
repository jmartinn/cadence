@testable import Cadence
import CadenceKit
import Foundation
import SwiftData
import Testing

struct BackupServiceRestoreTests {
    let container = CadenceStore.inMemory()

    private func doc(_ subs: [BackupSubscription], anchor: BackupAnchor?) -> BackupDocument {
        BackupDocument(exportedAt: Date(timeIntervalSince1970: 1_700_000_000),
                       appVersion: nil, subscriptions: subs, anchor: anchor)
    }

    @Test func restoreReplacesExistingData() throws {
        let context = ModelContext(container)
        context.insert(Subscription(name: "Old", amount: 1, billingCycle: .monthly,
                                    anchorDate: .distantPast, category: "Utilities"))
        try context.setAnchor(balance: 5, asOfDate: Date(timeIntervalSince1970: 1))
        try context.save()

        let new = BackupSubscription(id: UUID(), name: "Spotify", amount: Decimal(string: "5.99")!,
                                     billingCycle: .monthly, anchorDate: Date(timeIntervalSince1970: 1_000_000),
                                     status: .active, category: "Music")
        try BackupService.restore(doc([new], anchor: BackupAnchor(
            balance: Decimal(string: "1000.00")!, asOfDate: Date(timeIntervalSince1970: 2_000_000),
            monthlyIncome: 0, incomePayday: .distantPast
        )), into: context)

        let subs = try context.fetch(FetchDescriptor<Subscription>())
        #expect(subs.count == 1)
        #expect(subs.first?.name == "Spotify")
        #expect(subs.first?.amount == Decimal(string: "5.99")!)
        #expect(try context.currentAnchor()?.balance == Decimal(string: "1000.00")!)
    }

    @Test func restoreRebuildsAddOnTree() throws {
        let context = ModelContext(container)
        let parentID = UUID()
        let parent = BackupSubscription(id: parentID, name: "Amazon Prime",
                                        amount: Decimal(string: "8.99")!, billingCycle: .monthly,
                                        anchorDate: .distantPast, status: .active, category: "Shopping")
        let child = BackupSubscription(id: UUID(), name: "Paramount+",
                                       amount: Decimal(string: "7.99")!, billingCycle: .monthly,
                                       anchorDate: .distantPast, status: .active, category: "Entertainment",
                                       parentID: parentID)
        try BackupService.restore(doc([parent, child], anchor: nil), into: context)

        let subs = try context.fetch(FetchDescriptor<Subscription>())
        let primeModel = try #require(subs.first { $0.name == "Amazon Prime" })
        let paramountModel = try #require(subs.first { $0.name == "Paramount+" })
        #expect(paramountModel.parent === primeModel)
        #expect(primeModel.addOns.contains { $0 === paramountModel })
    }

    @Test func restoreWithEmptyDocumentClearsEverything() throws {
        let context = ModelContext(container)
        context.insert(Subscription(name: "Old", amount: 1, billingCycle: .monthly,
                                    anchorDate: .distantPast, category: "Utilities"))
        try context.setAnchor(balance: 5, asOfDate: Date(timeIntervalSince1970: 1))
        try context.save()

        try BackupService.restore(doc([], anchor: nil), into: context)

        #expect(try context.fetch(FetchDescriptor<Subscription>()).isEmpty)
        #expect(try context.currentAnchor() == nil)
    }

    @Test func exportThenRestoreReproducesState() throws {
        let source = ModelContext(container)
        let prime = Subscription(name: "Amazon Prime", amount: Decimal(string: "8.99")!,
                                 billingCycle: .yearly, anchorDate: Date(timeIntervalSince1970: 1_000_000),
                                 category: "Shopping", serviceKey: "amazon-prime",
                                 paymentBrand: "Visa", paymentLast4: "4821")
        let paramount = Subscription(name: "Paramount+", amount: Decimal(string: "7.99")!,
                                     billingCycle: .monthly, anchorDate: Date(timeIntervalSince1970: 2_000_000),
                                     status: .paused, category: "Entertainment")
        source.insert(prime); source.insert(paramount)
        paramount.parent = prime
        try source.setAnchor(balance: Decimal(string: "1025.06")!,
                             asOfDate: Date(timeIntervalSince1970: 1_500_000))
        try source.save()

        let document = try BackupService.export(from: source,
                                                exportedAt: Date(timeIntervalSince1970: 1_700_000_000),
                                                appVersion: "1.0")

        // Restore into a fresh, separate store and assert the world matches.
        let dest = ModelContext(CadenceStore.inMemory())
        try BackupService.restore(document, into: dest)

        let subs = try dest.fetch(FetchDescriptor<Subscription>()).sorted { $0.name < $1.name }
        #expect(subs.count == 2)
        let primeOut = try #require(subs.first { $0.name == "Amazon Prime" })
        let paramountOut = try #require(subs.first { $0.name == "Paramount+" })
        #expect(primeOut.amount == Decimal(string: "8.99")!)
        #expect(primeOut.billingCycle == .yearly)
        #expect(primeOut.paymentLast4 == "4821")
        #expect(paramountOut.status == .paused)
        #expect(paramountOut.parent === primeOut)
        #expect(try dest.currentAnchor()?.balance == Decimal(string: "1025.06")!)
    }
}
