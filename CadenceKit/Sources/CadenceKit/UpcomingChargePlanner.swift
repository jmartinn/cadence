import Foundation

/// Pure planner: turns snapshot entries into the soonest upcoming charges. Mirrors
/// `ReminderPlanner` — filters to `.active`, finds each next occurrence via `BillingSchedule`,
/// sorts ascending by date, truncates to `limit`. No SwiftData, no SwiftUI.
public enum UpcomingChargePlanner {
    public static func upcoming(
        from entries: [WidgetSnapshot.Entry],
        now: Date,
        limit: Int,
        calendar: Calendar = .current
    ) -> [UpcomingCharge] {
        var charges: [UpcomingCharge] = []
        for entry in entries where entry.status == .active {
            let schedule = BillingSchedule(anchorDate: entry.anchorDate,
                                           cycle: entry.billingCycle, calendar: calendar)
            guard let date = schedule.nextOccurrence(after: now) else { continue }
            charges.append(UpcomingCharge(name: entry.name, serviceKey: entry.serviceKey,
                                          amount: entry.amount, date: date))
        }
        charges.sort { $0.date < $1.date }
        return limit < charges.count ? Array(charges.prefix(limit)) : charges
    }
}
