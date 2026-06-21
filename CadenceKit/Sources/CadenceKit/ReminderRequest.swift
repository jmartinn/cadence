import Foundation

/// A single scheduled reminder, fully resolved: the planner emits these and the app-side
/// scheduler turns each into a `UNNotificationRequest`. Pure data — no UserNotifications types.
public struct ReminderRequest: Sendable, Equatable, Identifiable {
    /// Stable, prefixed id (`cadence.reminder.<target>.<epoch>`) so the scheduler only ever
    /// removes/adds its own notifications.
    public let id: String
    /// Exact local fire moment (09:00 on charge − lead).
    public let fireDate: Date
    public let title: String
    public let body: String

    public init(id: String, fireDate: Date, title: String, body: String) {
        self.id = id
        self.fireDate = fireDate
        self.title = title
        self.body = body
    }
}
