import Testing
import Foundation
@testable import Cadence

struct MonthNavigationTests {
    private var utc: Calendar {
        var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(identifier: "UTC")!; return c
    }
    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        utc.date(from: DateComponents(year: y, month: m, day: d))!
    }

    // MARK: - startOfMonth

    @Test func startOfMonthReturnsFirstDayAtMidnight() {
        let mid = date(2026, 3, 15)
        let start = MonthNavigation.startOfMonth(for: mid, calendar: utc)
        let comps = utc.dateComponents([.year, .month, .day, .hour, .minute, .second], from: start)
        #expect(comps.year == 2026)
        #expect(comps.month == 3)
        #expect(comps.day == 1)
        #expect(comps.hour == 0)
        #expect(comps.minute == 0)
        #expect(comps.second == 0)
    }

    @Test func startOfMonthIdempotentWhenAlreadyOnFirst() {
        let first = date(2026, 5, 1)
        let start = MonthNavigation.startOfMonth(for: first, calendar: utc)
        #expect(utc.isDate(start, inSameDayAs: first))
    }

    // MARK: - canGoBack

    @Test func canGoBackIsFalseAtFloor() {
        // displayedMonth is the same month as today → cannot go back
        let today = date(2026, 6, 15)
        let displayedMonth = date(2026, 6, 1)
        #expect(MonthNavigation.canGoBack(from: displayedMonth, today: today, calendar: utc) == false)
    }

    @Test func canGoBackIsFalseWhenDisplayedMonthIsTodaysMidMonth() {
        // Even if displayedMonth is mid-month but still within today's month
        let today = date(2026, 6, 15)
        let displayedMonth = date(2026, 6, 20)
        #expect(MonthNavigation.canGoBack(from: displayedMonth, today: today, calendar: utc) == false)
    }

    @Test func canGoBackIsTrueWhenDisplayedMonthIsInFuture() {
        let today = date(2026, 6, 15)
        let displayedMonth = date(2026, 7, 1)
        #expect(MonthNavigation.canGoBack(from: displayedMonth, today: today, calendar: utc) == true)
    }

    @Test func canGoBackIsTrueForDistantFutureMonth() {
        let today = date(2026, 6, 15)
        let displayedMonth = date(2027, 1, 1)
        #expect(MonthNavigation.canGoBack(from: displayedMonth, today: today, calendar: utc) == true)
    }

    // MARK: - advanced(from:by:today:calendar:)

    @Test func advancedByPlusOneReturnsNextMonthStart() {
        let today = date(2026, 6, 15)
        let current = date(2026, 6, 1)
        let next = MonthNavigation.advanced(from: current, by: 1, today: today, calendar: utc)
        let comps = utc.dateComponents([.year, .month, .day], from: next)
        #expect(comps.year == 2026)
        #expect(comps.month == 7)
        #expect(comps.day == 1)
    }

    @Test func advancedByMinusOneFromFutureMonthReturnsEarlierMonthStart() {
        let today = date(2026, 6, 15)
        // displayed is July 2026; going back one should yield June 2026
        let futureMonth = date(2026, 7, 1)
        let prev = MonthNavigation.advanced(from: futureMonth, by: -1, today: today, calendar: utc)
        let comps = utc.dateComponents([.year, .month, .day], from: prev)
        #expect(comps.year == 2026)
        #expect(comps.month == 6)
        #expect(comps.day == 1)
    }

    @Test func advancedByMinusOneAtFloorReturnsFloorUnchanged() {
        // Clamp: cannot go before the floor (today's month)
        let today = date(2026, 6, 15)
        let floorMonth = date(2026, 6, 1)
        let result = MonthNavigation.advanced(from: floorMonth, by: -1, today: today, calendar: utc)
        let comps = utc.dateComponents([.year, .month], from: result)
        #expect(comps.year == 2026)
        #expect(comps.month == 6)
    }

    @Test func advancedByMinusTwoFromOneMonthAheadClampsToFloor() {
        // displayed is July 2026 (one month ahead); -2 would land on May 2026 (past) → clamp to June
        let today = date(2026, 6, 15)
        let oneAhead = date(2026, 7, 1)
        let result = MonthNavigation.advanced(from: oneAhead, by: -2, today: today, calendar: utc)
        let comps = utc.dateComponents([.year, .month], from: result)
        #expect(comps.year == 2026)
        #expect(comps.month == 6)
    }

    @Test func advancedByPlusOneAcrossYearBoundary() {
        let today = date(2026, 12, 1)
        let december = date(2026, 12, 1)
        let next = MonthNavigation.advanced(from: december, by: 1, today: today, calendar: utc)
        let comps = utc.dateComponents([.year, .month], from: next)
        #expect(comps.year == 2027)
        #expect(comps.month == 1)
    }
}
