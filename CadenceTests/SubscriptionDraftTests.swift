@testable import Cadence
import CadenceKit
import Foundation
import Testing

struct SubscriptionDraftTests {
    private func baseDraft() -> SubscriptionDraft {
        SubscriptionDraft(
            name: "Netflix", amount: "17.99", billingCycle: .monthly,
            anchorDate: Date(timeIntervalSince1970: 0), category: .entertainment,
            paymentBrand: "Visa", paymentLast4: "4821"
        )
    }

    @Test func validDraftHasNoError() {
        #expect(baseDraft().validationError == nil)
        #expect(baseDraft().isValid)
    }

    @Test func emptyOrWhitespaceNameIsInvalid() {
        var d = baseDraft(); d.name = "   "
        #expect(d.validationError == .emptyName)
    }

    @Test func nonPositiveOrUnparseableAmountIsInvalid() {
        var d = baseDraft(); d.amount = "0"
        #expect(d.validationError == .invalidAmount)
        d.amount = "-5"
        #expect(d.validationError == .invalidAmount)
        d.amount = "abc"
        #expect(d.validationError == .invalidAmount)
        d.amount = ""
        #expect(d.validationError == .invalidAmount)
    }

    @Test func last4MustBeEmptyOrFourDigits() {
        var d = baseDraft(); d.paymentLast4 = ""
        #expect(d.validationError == nil)            // empty is allowed
        d.paymentLast4 = "482"
        #expect(d.validationError == .invalidLast4)
        d.paymentLast4 = "48211"
        #expect(d.validationError == .invalidLast4)
        d.paymentLast4 = "48a1"
        #expect(d.validationError == .invalidLast4)
        d.paymentLast4 = "4821"
        #expect(d.validationError == nil)
    }

    @Test func roundTripsThroughModelAndNilsEmptyPaymentFields() {
        let source = Subscription(
            name: "Spotify", amount: Decimal(string: "10.99")!, billingCycle: .yearly,
            anchorDate: Date(timeIntervalSince1970: 1000), category: "Music",
            paymentBrand: "Mastercard", paymentLast4: "1234"
        )
        let draft = SubscriptionDraft(from: source)
        let dest = Subscription(name: "", amount: 0, billingCycle: .monthly,
                                anchorDate: .distantPast, category: "")
        draft.apply(to: dest, parent: nil)
        #expect(dest.name == "Spotify")
        #expect(dest.amount == Decimal(string: "10.99")!)
        #expect(dest.billingCycle == .yearly)
        #expect(dest.category == "Music")
        #expect(dest.paymentBrand == "Mastercard")
        #expect(dest.paymentLast4 == "1234")

        var blankPay = SubscriptionDraft(from: source)
        blankPay.paymentBrand = "  "
        blankPay.paymentLast4 = ""
        blankPay.apply(to: dest, parent: nil)
        #expect(dest.paymentBrand == nil)
        #expect(dest.paymentLast4 == nil)
    }

    @Test func emptyDraftDefaultsToOtherCategory() {
        #expect(SubscriptionDraft.empty(now: Date(timeIntervalSince1970: 0)).category == .other)
    }

    @Test func initFromModelCoercesCategory() {
        let known = Subscription(name: "N", amount: Decimal(string: "1.00")!, billingCycle: .monthly,
                                 anchorDate: .distantPast, category: "Music")
        #expect(SubscriptionDraft(from: known).category == .music)

        let unknown = Subscription(name: "N", amount: Decimal(string: "1.00")!, billingCycle: .monthly,
                                   anchorDate: .distantPast, category: "Streaming")
        #expect(SubscriptionDraft(from: unknown).category == .other)
    }

    @Test func applyWritesCategoryRawValue() {
        var d = baseDraft()
        d.category = .developerTools
        let dest = Subscription(name: "", amount: 0, billingCycle: .monthly,
                                anchorDate: .distantPast, category: "")
        d.apply(to: dest, parent: nil)
        #expect(dest.category == "Developer Tools")
    }
}
