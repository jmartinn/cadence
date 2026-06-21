import Foundation

/// How far ahead of a charge a renewal reminder fires. A single global setting (not
/// per-subscription). `String`-backed so it persists cleanly in `@AppStorage`; the
/// rawValues are a storage contract — never rename them.
public enum ReminderLeadTime: String, CaseIterable, Identifiable, Sendable {
    case sameDay
    case oneDay
    case twoDays
    case threeDays
    case oneWeek

    public var id: String { rawValue }

    /// Calendar days subtracted from the charge date to get the reminder's day.
    public var daysBefore: Int {
        switch self {
        case .sameDay: return 0
        case .oneDay: return 1
        case .twoDays: return 2
        case .threeDays: return 3
        case .oneWeek: return 7
        }
    }

    /// Picker label.
    public var displayName: String {
        switch self {
        case .sameDay: return "On the day"
        case .oneDay: return "1 day before"
        case .twoDays: return "2 days before"
        case .threeDays: return "3 days before"
        case .oneWeek: return "1 week before"
        }
    }

    /// Notification copy fragment: "Netflix renews \(relativePhrase)". Derived from the lead
    /// time only (a fixed lead → a fixed phrase), so the wording stays correct no matter when
    /// iOS delivers the notification.
    public var relativePhrase: String {
        switch self {
        case .sameDay: return "today"
        case .oneDay: return "tomorrow"
        case .twoDays: return "in 2 days"
        case .threeDays: return "in 3 days"
        case .oneWeek: return "in a week"
        }
    }
}
