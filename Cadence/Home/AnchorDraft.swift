import Foundation
import SwiftData

/// Editable, validatable state for the anchor/income sheet — pure, so it unit-tests without
/// SwiftUI (mirrors `SubscriptionDraft`). `balance`/`monthlyIncome` are `String` (raw input);
/// parsing is locale-aware via `Decimal(string:locale:)` — never a hardcoded separator.
struct AnchorDraft: Equatable {
    var balance: String
    var asOfDate: Date
    var monthlyIncome: String
    var payday: Date

    enum Invalid: Equatable { case invalidBalance, invalidIncome }

    init(balance: String = "", asOfDate: Date, monthlyIncome: String = "", payday: Date) {
        self.balance = balance
        self.asOfDate = asOfDate
        self.monthlyIncome = monthlyIncome
        self.payday = payday
    }

    /// Blank draft for first-time setup. `now` injected (no `Date()` side effect) for testability.
    static func empty(now: Date) -> AnchorDraft {
        AnchorDraft(balance: "", asOfDate: now, monthlyIncome: "", payday: now)
    }

    /// Seed from an existing anchor (edit).
    init(from anchor: BalanceAnchor) {
        balance = Self.amountString(anchor.balance)
        asOfDate = anchor.asOfDate
        monthlyIncome = anchor.monthlyIncome > 0 ? Self.amountString(anchor.monthlyIncome) : ""
        payday = anchor.incomePayday == .distantPast ? anchor.asOfDate : anchor.incomePayday
    }

    var parsedBalance: Decimal? {
        let t = balance.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return nil }
        return Decimal(string: t, locale: .current)
    }

    /// Empty income means "no income" → 0. Non-empty must parse; `nil` signals unparseable.
    var parsedIncome: Decimal? {
        let t = monthlyIncome.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return .zero }
        return Decimal(string: t, locale: .current)
    }

    var validationError: Invalid? {
        guard parsedBalance != nil else { return .invalidBalance }
        guard let income = parsedIncome, income >= 0 else { return .invalidIncome }
        return nil
    }

    var isValid: Bool { validationError == nil }

    /// Upsert the anchor. Income ≤ 0 / empty clears the income fields. Call only when `isValid`.
    func apply(via context: ModelContext) throws {
        guard let bal = parsedBalance, let income = parsedIncome else { return }
        let hasIncome = income > 0
        try context.setAnchor(
            balance: bal,
            asOfDate: asOfDate,
            monthlyIncome: hasIncome ? income : 0,
            incomePayday: hasIncome ? payday : .distantPast
        )
    }

    /// Localized prefill (no grouping) so it round-trips through `parsedBalance`/`parsedIncome`.
    private static func amountString(_ d: Decimal) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.usesGroupingSeparator = false
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        return f.string(from: d as NSDecimalNumber) ?? ""
    }
}
