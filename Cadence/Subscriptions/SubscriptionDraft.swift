import CadenceKit
import Foundation

/// Editable, validatable form state for the Add/Edit sheet — the only non-trivial logic in the
/// form, kept pure so it unit-tests without SwiftUI (mirrors `SubscriptionListPresenter`).
/// `amount` and `paymentLast4` are `String` because they are raw text input.
struct SubscriptionDraft: Sendable, Equatable {
    var name: String = ""
    var amount: String = ""
    var billingCycle: BillingCycle = .monthly
    var anchorDate: Date
    var category: String = ""
    var paymentBrand: String = ""
    var paymentLast4: String = ""

    enum Invalid: Equatable { case emptyName, invalidAmount, invalidLast4 }

    init(
        name: String = "",
        amount: String = "",
        billingCycle: BillingCycle = .monthly,
        anchorDate: Date,
        category: String = "",
        paymentBrand: String = "",
        paymentLast4: String = ""
    ) {
        self.name = name
        self.amount = amount
        self.billingCycle = billingCycle
        self.anchorDate = anchorDate
        self.category = category
        self.paymentBrand = paymentBrand
        self.paymentLast4 = paymentLast4
    }

    /// Blank draft for Add mode. `now` is injected (no `Date()` side effect) for testability.
    static func empty(now: Date) -> SubscriptionDraft { SubscriptionDraft(anchorDate: now) }

    /// Seed for Edit mode.
    init(from sub: Subscription) {
        name = sub.name
        amount = Self.amountString(sub.amount)
        billingCycle = sub.billingCycle
        anchorDate = sub.anchorDate
        category = sub.category
        paymentBrand = sub.paymentBrand ?? ""
        paymentLast4 = sub.paymentLast4 ?? ""
    }

    /// Parses `amount` using the device locale's decimal separator ("," in es, "." in en).
    var parsedAmount: Decimal? {
        let trimmed = amount.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        return Decimal(string: trimmed, locale: .current)
    }

    var validationError: Invalid? {
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return .emptyName }
        guard let amt = parsedAmount, amt > 0 else { return .invalidAmount }
        let last4 = paymentLast4.trimmingCharacters(in: .whitespaces)
        if !last4.isEmpty, !(last4.count == 4 && last4.allSatisfy(\.isNumber)) { return .invalidLast4 }
        return nil
    }

    var isValid: Bool { validationError == nil }

    /// Writes validated values onto a model. Empty payment fields become `nil` so the detail
    /// row hides cleanly. Call only when `isValid`.
    func apply(to sub: Subscription) {
        sub.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if let amt = parsedAmount { sub.amount = amt }
        sub.billingCycle = billingCycle
        sub.anchorDate = anchorDate
        sub.category = category.trimmingCharacters(in: .whitespacesAndNewlines)
        let brand = paymentBrand.trimmingCharacters(in: .whitespaces)
        let last4 = paymentLast4.trimmingCharacters(in: .whitespaces)
        sub.paymentBrand = brand.isEmpty ? nil : brand
        sub.paymentLast4 = last4.isEmpty ? nil : last4
    }

    /// Localized prefill (no grouping) so it round-trips through `parsedAmount`: 17.99 -> "17,99" (es) / "17.99" (en).
    private static func amountString(_ d: Decimal) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.usesGroupingSeparator = false
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        return f.string(from: d as NSDecimalNumber) ?? ""
    }
}
