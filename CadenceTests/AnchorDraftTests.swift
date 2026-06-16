@testable import Cadence
import Foundation
import SwiftData
import Testing

struct AnchorDraftTests {
    private let day0 = Date(timeIntervalSince1970: 0)
    private let day1 = Date(timeIntervalSince1970: 86_400)

    private func draft(balance: String, income: String = "") -> AnchorDraft {
        AnchorDraft(balance: balance, asOfDate: day0, monthlyIncome: income, payday: day1)
    }

    @Test func validWithBalanceAndIncome() {
        #expect(draft(balance: "1000.00", income: "2000.00").validationError == nil)
    }

    @Test func emptyIncomeIsZeroAndValid() {
        let d = draft(balance: "1000.00", income: "")
        #expect(d.parsedIncome == 0)
        #expect(d.isValid)
    }

    @Test func balanceIsRequired() {
        #expect(draft(balance: "").validationError == .invalidBalance)
        #expect(draft(balance: "abc").validationError == .invalidBalance)
    }

    @Test func negativeBalanceIsAllowed() {
        #expect(draft(balance: "-50.00").validationError == nil)   // overdraft
    }

    @Test func negativeOrUnparseableIncomeIsInvalid() {
        #expect(draft(balance: "10.00", income: "-5").validationError == .invalidIncome)
        #expect(draft(balance: "10.00", income: "abc").validationError == .invalidIncome)
    }

    @Test func applyUpsertsAnchorWithIncome() throws {
        let context = ModelContext(CadenceStore.inMemory())
        var d = AnchorDraft(balance: "1000.00", asOfDate: day0, monthlyIncome: "2000.00", payday: day1)
        try d.apply(via: context)
        let got = try #require(try context.currentAnchor())
        #expect(got.balance == Decimal(string: "1000.00")!)
        #expect(got.monthlyIncome == Decimal(string: "2000.00")!)
        #expect(got.incomePayday == day1)

        d.monthlyIncome = ""                  // clear income → 0 / distantPast
        try d.apply(via: context)
        let cleared = try #require(try context.currentAnchor())
        #expect(cleared.monthlyIncome == 0)
        #expect(cleared.incomePayday == .distantPast)
    }

    @Test func seedsFromExistingAnchor() {
        let anchor = BalanceAnchor(balance: Decimal(string: "12.50")!, asOfDate: day0,
                                   monthlyIncome: Decimal(string: "99.00")!, incomePayday: day1)
        let d = AnchorDraft(from: anchor)
        #expect(d.parsedBalance == Decimal(string: "12.50")!)
        #expect(d.parsedIncome == Decimal(string: "99.00")!)
        #expect(d.payday == day1)
    }
}
