import Foundation

/// One resolved upcoming charge for the widget: which service, how much, and when. Pure value —
/// no SwiftData, no SwiftUI.
public struct UpcomingCharge: Equatable, Sendable {
    public let name: String
    public let serviceKey: String?
    public let amount: Decimal
    public let date: Date

    public init(name: String, serviceKey: String?, amount: Decimal, date: Date) {
        self.name = name
        self.serviceKey = serviceKey
        self.amount = amount
        self.date = date
    }
}
