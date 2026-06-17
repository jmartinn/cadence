@testable import Cadence
import CadenceKit
import Foundation
import SwiftData
import Testing

struct SubscriptionAddOnLogicTests {
    private func make(_ name: String, _ amount: String, _ status: SubscriptionStatus = .active) -> Subscription {
        Subscription(name: name, amount: Decimal(string: amount)!, billingCycle: .monthly,
                     anchorDate: .now, status: status, category: "Test")
    }

    @Test func eligibleParentsExcludesSelfAndNonStandalone() throws {
        let ctx = ModelContext(CadenceStore.inMemory())
        let prime = make("Amazon Prime", "8.99")
        let netflix = make("Netflix", "17.99")
        let paramount = make("Paramount+", "7.99")
        [prime, netflix, paramount].forEach(ctx.insert)
        paramount.parent = prime          // paramount is now an add-on (non-standalone)
        try ctx.save()

        // Editing netflix: only standalone, non-self subs qualify => Amazon Prime.
        let cands = SubscriptionListPresenter.eligibleParents(
            for: netflix, among: [prime, netflix, paramount]
        )
        #expect(cands.map(\.name) == ["Amazon Prime"])
    }

    @Test func canHaveParentIsFalseOnlyWhenSubAlreadyHasAddOns() throws {
        let ctx = ModelContext(CadenceStore.inMemory())
        let prime = make("Amazon Prime", "8.99")
        let netflix = make("Netflix", "17.99")
        let paramount = make("Paramount+", "7.99")
        [prime, netflix, paramount].forEach(ctx.insert)
        paramount.parent = prime
        try ctx.save()

        #expect(SubscriptionListPresenter.canHaveParent(prime) == false)  // prime is a parent
        #expect(SubscriptionListPresenter.canHaveParent(netflix) == true)
        #expect(SubscriptionListPresenter.canHaveParent(paramount) == true) // add-on can re-link
        #expect(SubscriptionListPresenter.canHaveParent(nil) == true)      // add mode
    }

    @Test func applyLinksAndClearsParent() {
        let ctx = ModelContext(CadenceStore.inMemory())
        let prime = make("Amazon Prime", "8.99")
        let netflix = make("Netflix", "17.99")
        [prime, netflix].forEach(ctx.insert)

        var draft = SubscriptionDraft(from: netflix)
        draft.apply(to: netflix, parent: prime)
        #expect(netflix.parent === prime)

        draft.apply(to: netflix, parent: nil)
        #expect(netflix.parent == nil)
    }

    @Test func combinedMonthlySumsActiveParentAndAddOns() throws {
        let ctx = ModelContext(CadenceStore.inMemory())
        let prime = make("Amazon Prime", "8.99")
        let paramount = make("Paramount+", "7.99")
        let mtv = make("MTV", "5.00", .paused)   // paused => excluded from the total
        [prime, paramount, mtv].forEach(ctx.insert)
        paramount.parent = prime
        mtv.parent = prime
        try ctx.save()

        #expect(SubscriptionListPresenter.combinedMonthly(for: prime) == Decimal(string: "16.98")!)
    }

    @Test func forecastCountsAddOnsAsIndependentSubs() throws {
        // Guard: linking a sub as an add-on must not change how the forecast sums it — the
        // total of a parent + its add-on equals the sum of the two as independent subs.
        let ctx = ModelContext(CadenceStore.inMemory())
        let prime = make("Amazon Prime", "8.99")
        let paramount = make("Paramount+", "7.99")
        [prime, paramount].forEach(ctx.insert)
        paramount.parent = prime
        try ctx.save()

        let forecaster = Forecaster(anchorBalance: 0, asOfDate: .distantPast,
                                    subscriptions: [prime, paramount].map(\.plan))
        #expect(forecaster.monthlyTotal == Decimal(string: "16.98")!)
    }
}
