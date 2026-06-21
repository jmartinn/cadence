// Cadence/Reminders/ReminderScheduler.swift
import CadenceKit
import Foundation
import UserNotifications

/// Thin adapter over `UNUserNotificationCenter`. Owns no scheduling logic — it just asks for
/// permission and replaces *our* pending notifications (those with the `cadence.reminder.`
/// prefix) with a freshly computed set. All date/content decisions live in `ReminderPlanner`.
@MainActor
struct ReminderScheduler {
    private let center = UNUserNotificationCenter.current()
    private static let idPrefix = "cadence.reminder."

    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    /// Prompts only when status is `.notDetermined`; returns whether we are authorized.
    func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    /// Cancel every reminder we previously scheduled, then add the new set. Foreign
    /// notifications (not our prefix) are never touched.
    func sync(_ requests: [ReminderRequest], calendar: Calendar = .current) async {
        let pending = await center.pendingNotificationRequests()
        let ours = pending.map(\.identifier).filter { $0.hasPrefix(Self.idPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: ours)

        for request in requests {
            let content = UNMutableNotificationContent()
            content.title = request.title
            content.body = request.body
            content.sound = .default

            let comps = calendar.dateComponents([.year, .month, .day, .hour, .minute],
                                                from: request.fireDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            let unRequest = UNNotificationRequest(identifier: request.id, content: content,
                                                  trigger: trigger)
            try? await center.add(unRequest)
        }
    }
}
