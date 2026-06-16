import Foundation

/// Pure namespace of stateless helpers for forward-only month navigation.
/// The floor is always the calendar month that contains `today`; the UI
/// never allows browsing to a month earlier than that.
enum MonthNavigation {
    /// Returns the first instant (00:00:00) of the calendar month that
    /// contains `date`, according to the supplied `calendar`.
    static func startOfMonth(for date: Date, calendar: Calendar) -> Date {
        let comps = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: comps)!
    }

    /// `true` when `displayedMonth` is a later month than `today`'s month,
    /// meaning the user can navigate backward.  Always `false` when
    /// `displayedMonth` is in the same month as `today` (the floor).
    static func canGoBack(from displayedMonth: Date, today: Date, calendar: Calendar) -> Bool {
        let floorStart = startOfMonth(for: today, calendar: calendar)
        let displayedStart = startOfMonth(for: displayedMonth, calendar: calendar)
        return displayedStart > floorStart
    }

    /// Returns the start of the month that is `months` months after
    /// `displayedMonth`, clamped so the result is never earlier than the
    /// floor (the start of `today`'s month).
    ///
    /// Examples:
    /// - `advanced(from: june, by: +1, …)` → July's start
    /// - `advanced(from: july, by: -1, …)` → June's start
    /// - `advanced(from: june, by: -1, …)` → June's start (clamped at floor)
    static func advanced(
        from displayedMonth: Date,
        by months: Int,
        today: Date,
        calendar: Calendar
    ) -> Date {
        let displayedStart = startOfMonth(for: displayedMonth, calendar: calendar)
        let floorStart = startOfMonth(for: today, calendar: calendar)

        guard let candidate = calendar.date(
            byAdding: .month, value: months, to: displayedStart
        ) else {
            return floorStart
        }

        return max(candidate, floorStart)
    }
}
