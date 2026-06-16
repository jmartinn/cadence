import Foundation

/// Builds the read-only month grid for the Home calendar. Pure value type — tested with
/// directly-constructed `Subscription` instances (the `RecentCharges` precedent). Monday-first
/// regardless of locale (computed explicitly, not via `Calendar.firstWeekday`).
enum MonthCalendar {
    struct Marker: Equatable {
        let serviceName: String   // → monogram
        let hasCard: Bool         // paymentBrand & paymentLast4 both set → blue debit badge
        let subscription: Subscription   // originating model, for tap-to-detail
    }

    struct Day: Identifiable, Equatable {
        let date: Date            // start of day
        let isInMonth: Bool       // false for leading/trailing padding cells
        let isToday: Bool
        let markers: [Marker]
        var id: Date { date }
    }

    struct Week: Identifiable, Equatable {
        let days: [Day]           // exactly 7, Monday-first
        var id: Date { days.first?.date ?? .distantPast }
    }

    static func weeks(
        for month: Date,
        subscriptions: [Subscription],
        today: Date,
        calendar: Calendar = .current
    ) -> [Week] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: month),
              let daysInMonth = calendar.range(of: .day, in: .month, for: month)?.count
        else { return [] }
        let monthStart = monthInterval.start

        // Monday-based leading offset: Mon→0 … Sun→6 (weekday is 1=Sun … 7=Sat in Gregorian).
        let weekday = calendar.component(.weekday, from: monthStart)
        let leading = (weekday + 5) % 7
        guard let gridStart = calendar.date(byAdding: .day, value: -leading, to: monthStart) else { return [] }
        let totalCells = Int((Double(leading + daysInMonth) / 7).rounded(.up)) * 7

        // Markers per start-of-day for active subscriptions whose charge lands this month.
        var markersByDay: [Date: [Marker]] = [:]
        for sub in subscriptions where sub.status == .active {
            let schedule = BillingSchedule(anchorDate: sub.anchorDate, cycle: sub.billingCycle, calendar: calendar)
            for charge in schedule.occurrences(in: monthInterval) where charge < monthInterval.end {
                let key = calendar.startOfDay(for: charge)
                let hasCard = sub.paymentBrand != nil && sub.paymentLast4 != nil
                markersByDay[key, default: []].append(Marker(serviceName: sub.name, hasCard: hasCard, subscription: sub))
            }
        }

        var allDays: [Day] = []
        for i in 0..<totalCells {
            guard let date = calendar.date(byAdding: .day, value: i, to: gridStart) else { continue }
            let startOfDay = calendar.startOfDay(for: date)
            let isInMonth = calendar.isDate(date, equalTo: monthStart, toGranularity: .month)
            let isToday = calendar.isDate(date, inSameDayAs: today)
            let markers = isInMonth ? (markersByDay[startOfDay] ?? []) : []
            allDays.append(Day(date: startOfDay, isInMonth: isInMonth, isToday: isToday, markers: markers))
        }

        return stride(from: 0, to: allDays.count, by: 7).map { start in
            Week(days: Array(allDays[start..<min(start + 7, allDays.count)]))
        }
    }
}
