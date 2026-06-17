@testable import Cadence
import CadenceKit
import Foundation
import SwiftData
import Testing

struct SubscriptionRelationshipTests {
    @Test func migratesV1StoreToV2WithDefaults() throws {
        let url = URL.temporaryDirectory.appending(path: "cadence-mig-\(UUID().uuidString).store")
        defer { try? FileManager.default.removeItem(at: url) }

        // 1. Create and populate a real V1-shaped on-disk store.
        do {
            let v1 = Schema(versionedSchema: CadenceSchemaV1.self)
            let config = ModelConfiguration(schema: v1, url: url, cloudKitDatabase: .none)
            let container = try ModelContainer(for: v1, configurations: config)
            let ctx = ModelContext(container)
            ctx.insert(CadenceSchemaV1.Subscription(
                name: "Netflix", amount: Decimal(string: "17.99")!, billingCycle: .monthly,
                anchorDate: .now, status: .active, category: "Entertainment"
            ))
            try ctx.save()
        }

        // 2. Reopen at the same URL under V2 + migration plan.
        let v2 = Schema(versionedSchema: CadenceSchemaV2.self)
        let config = ModelConfiguration(schema: v2, url: url, cloudKitDatabase: .none)
        let container = try ModelContainer(
            for: v2, migrationPlan: CadenceMigrationPlan.self, configurations: config
        )
        let ctx = ModelContext(container)
        let subs = try ctx.fetch(FetchDescriptor<Subscription>())

        #expect(subs.count == 1)
        #expect(subs.first?.name == "Netflix")
        #expect(subs.first?.parent == nil)
        #expect(subs.first?.addOns.isEmpty == true)
    }

    @Test func linkingAnAddOnPopulatesTheInverse() throws {
        let ctx = ModelContext(CadenceStore.inMemory())
        let prime = Subscription(name: "Amazon Prime", amount: Decimal(string: "8.99")!,
                                 billingCycle: .monthly, anchorDate: .now, category: "Shopping")
        let paramount = Subscription(name: "Paramount+", amount: Decimal(string: "7.99")!,
                                     billingCycle: .monthly, anchorDate: .now, category: "Entertainment")
        ctx.insert(prime); ctx.insert(paramount)
        paramount.parent = prime
        try ctx.save()

        #expect(prime.addOns.count == 1)
        #expect(prime.addOns.first === paramount)
        #expect(paramount.parent === prime)
    }

    @Test func deletingParentNullifiesAddOnsRatherThanCascading() throws {
        let ctx = ModelContext(CadenceStore.inMemory())
        let prime = Subscription(name: "Amazon Prime", amount: Decimal(string: "8.99")!,
                                 billingCycle: .monthly, anchorDate: .now, category: "Shopping")
        let paramount = Subscription(name: "Paramount+", amount: Decimal(string: "7.99")!,
                                     billingCycle: .monthly, anchorDate: .now, category: "Entertainment")
        ctx.insert(prime); ctx.insert(paramount)
        paramount.parent = prime
        try ctx.save()

        ctx.delete(prime)
        try ctx.save()

        let remaining = try ctx.fetch(FetchDescriptor<Subscription>())
        #expect(remaining.count == 1)               // the add-on survived
        #expect(remaining.first?.name == "Paramount+")
        #expect(remaining.first?.parent == nil)     // and was nullified, not cascaded
    }
}
