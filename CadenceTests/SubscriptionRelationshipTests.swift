@testable import Cadence
import CadenceKit
import Foundation
import SwiftData
import Testing

/// Add-on relationship behavior (the display-only parent ↔ add-ons link).
///
/// These tests use `CadenceStore.inMemory()` (the V2 schema), which is safe to run in the
/// shared, parallel test host.
///
/// NOTE — why there is no in-process V1→V2 migration test: such a test must build a live
/// `Schema(versionedSchema: CadenceSchemaV1.self)` container, which registers a second entity
/// named `"Subscription"` (the V1 shape, without `addOns`). CoreData keys entities by name and
/// the registry is process-global, so coexisting with the V2 entity — always present because the
/// test host app loads `CadenceStore.live()` — intermittently binds a V2 object to the V1
/// description and aborts the host with an uncaught `NSUnknownKeyException` on `addOns`. The
/// V1→V2 migration is lightweight/additive and verified on-device (real iOS run). If a future
/// migration needs automated coverage, run it in its own non-app-hosted test target so the V1
/// and V2 schemas never share a process with the live V2 container.
struct SubscriptionRelationshipTests {
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
