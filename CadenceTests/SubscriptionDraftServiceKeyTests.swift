@testable import Cadence
import CadenceKit
import Foundation
import Testing

/// `serviceKey` round-trips through the form draft: seeded on edit, written on save,
/// cleared when the user picks "Automatic".
struct SubscriptionDraftServiceKeyTests {
    @Test func applyWritesServiceKey() {
        var draft = SubscriptionDraft.empty(now: .now)
        draft.name = "My Stuff"
        draft.amount = "9.99"
        draft.serviceKey = "spotify"
        let sub = Subscription(name: "", amount: 0, billingCycle: .monthly,
                               anchorDate: .distantPast, category: "")
        draft.apply(to: sub, parent: nil)
        #expect(sub.serviceKey == "spotify")
    }

    @Test func initFromSeedsServiceKey() {
        let sub = Subscription(name: "Netflix", amount: Decimal(string: "12.99")!,
                               billingCycle: .monthly, anchorDate: .now, category: "Entertainment")
        sub.serviceKey = "netflix"
        let draft = SubscriptionDraft(from: sub)
        #expect(draft.serviceKey == "netflix")
    }

    @Test func pickingAutomaticClearsServiceKey() {
        let sub = Subscription(name: "Netflix", amount: Decimal(string: "12.99")!,
                               billingCycle: .monthly, anchorDate: .now, category: "Entertainment")
        sub.serviceKey = "netflix"
        var draft = SubscriptionDraft(from: sub)
        draft.serviceKey = nil
        draft.apply(to: sub, parent: nil)
        #expect(sub.serviceKey == nil)
    }
}
