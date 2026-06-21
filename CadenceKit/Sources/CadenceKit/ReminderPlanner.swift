import Foundation

/// Pure planner: turns active subscriptions + a global lead time into the set of reminder
/// notifications that should currently be pending. No UserNotifications, no SwiftData, no UI —
/// unit-testable like `Forecaster`/`BillingSchedule`.
public enum ReminderPlanner {
    /// All reminder requests that should be pending, soonest first, capped to `cap`.
    ///
    /// - For each `.active` target, charge dates come from `BillingSchedule` over `horizon`.
    /// - Each fire date is 09:00 local on (charge − `leadTime.daysBefore`); already-elapsed
    ///   fire dates are dropped.
    /// - The combined list is sorted ascending by fire date and truncated to `cap` (≤ 64 so we
    ///   never exhaust iOS's pending-notification budget), which keeps the soonest reminders.
    public static func requests(
        for targets: [ReminderTarget],
        leadTime: ReminderLeadTime,
        now: Date,
        horizon: DateInterval,
        cap: Int = 60,
        calendar: Calendar = .current,
        formatAmount: (Decimal) -> String
    ) -> [ReminderRequest] {
        var requests: [ReminderRequest] = []

        for target in targets where target.plan.status == .active {
            let schedule = BillingSchedule(anchorDate: target.plan.anchorDate,
                                           cycle: target.plan.cycle, calendar: calendar)
            for charge in schedule.occurrences(in: horizon) {
                guard let fireDate = fireDate(forCharge: charge, leadTime: leadTime,
                                              calendar: calendar), fireDate > now else { continue }

                let epoch = Int(charge.timeIntervalSince1970)
                let request = ReminderRequest(
                    id: "cadence.reminder.\(target.id).\(epoch)",
                    fireDate: fireDate,
                    title: "\(target.name) renews \(leadTime.relativePhrase)",
                    body: "\(formatAmount(target.plan.amount)) will be charged."
                )
                requests.append(request)
            }
        }

        requests.sort { $0.fireDate < $1.fireDate }
        return cap < requests.count ? Array(requests.prefix(cap)) : requests
    }

    /// 09:00 local on (charge − lead days). Returns nil only if calendar math fails.
    private static func fireDate(forCharge charge: Date, leadTime: ReminderLeadTime,
                                 calendar: Calendar) -> Date? {
        guard let shifted = calendar.date(byAdding: .day, value: -leadTime.daysBefore,
                                          to: charge) else { return nil }
        var comps = calendar.dateComponents([.year, .month, .day], from: shifted)
        comps.hour = 9
        comps.minute = 0
        comps.second = 0
        return calendar.date(from: comps)
    }
}
