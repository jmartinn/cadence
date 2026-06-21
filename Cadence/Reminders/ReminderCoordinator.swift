// Cadence/Reminders/ReminderCoordinator.swift
import CadenceKit
import Foundation
import SwiftData
import UserNotifications

/// `@AppStorage`/`UserDefaults` keys for the reminder settings. Single source of truth so the
/// Settings UI (which writes) and the coordinator (which reads) can never drift. These strings
/// are a persistence contract — do not rename once shipped.
enum ReminderDefaults {
    static let enabledKey = "remindersEnabled"
    static let leadTimeKey = "reminderLeadTime"
}

/// App-side orchestrator. The one place that knows how to turn "the current world" (settings +
/// SwiftData) into a synced notification set. Called from every reschedule trigger.
@MainActor
struct ReminderCoordinator {
    var scheduler = ReminderScheduler()
    private let defaults: UserDefaults = .standard
    private static let horizonMonths = 6

    /// Recompute and re-sync all reminders. No-ops to an empty set (cancelling everything ours)
    /// when reminders are disabled or notifications aren't authorized.
    func reschedule(context: ModelContext, now: Date = .now, calendar: Calendar = .current) async {
        let enabled = defaults.bool(forKey: ReminderDefaults.enabledKey)
        let leadTime = ReminderLeadTime(
            rawValue: defaults.string(forKey: ReminderDefaults.leadTimeKey) ?? ReminderLeadTime.oneDay.rawValue
        ) ?? .oneDay

        guard enabled, await scheduler.authorizationStatus() == .authorized else {
            await scheduler.sync([])
            return
        }

        let subscriptions = (try? context.fetch(FetchDescriptor<Subscription>())) ?? []
        let targets = subscriptions.map {
            ReminderTarget(id: $0.serviceKey ?? $0.name, name: $0.name, plan: $0.plan)
        }

        guard let end = calendar.date(byAdding: .month, value: Self.horizonMonths, to: now) else {
            await scheduler.sync([])
            return
        }
        let requests = ReminderPlanner.requests(
            for: targets, leadTime: leadTime, now: now,
            horizon: DateInterval(start: now, end: end),
            calendar: calendar, formatAmount: PriceText.inlineString
        )
        await scheduler.sync(requests, calendar: calendar)
    }
}
