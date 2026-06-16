@testable import Cadence
import Foundation
import Testing

struct BillingScheduleTests {
    // MARK: - Deterministic date helpers

    /// Fixed UTC Gregorian calendar so tests don't depend on the machine's timezone.
    let utc: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }()

    /// A date at noon UTC on the given day (noon avoids DST/midnight edges).
    func day(_ year: Int, _ month: Int, _ d: Int) -> Date {
        utc.date(from: DateComponents(year: year, month: month, day: d, hour: 12))!
    }

    /// Build a schedule that uses the deterministic UTC calendar.
    func schedule(_ anchor: Date, _ cycle: BillingCycle) -> BillingSchedule {
        BillingSchedule(anchorDate: anchor, cycle: cycle, calendar: utc)
    }

    // MARK: - Tests

    @Test func monthlyOccurrencesWithinRange() {
        let sched = schedule(day(2025, 1, 15), .monthly)
        let result = sched.occurrences(in: DateInterval(start: day(2025, 1, 1), end: day(2025, 4, 30)))
        #expect(result == [day(2025, 1, 15), day(2025, 2, 15), day(2025, 3, 15), day(2025, 4, 15)])
    }

    @Test func monthlyClampsToShortMonths() {
        let sched = schedule(day(2025, 1, 31), .monthly)
        let result = sched.occurrences(in: DateInterval(start: day(2025, 1, 1), end: day(2025, 4, 30)))
        // Feb 2025 has 28 days; the "31" returns in March, proving we compute from the anchor.
        #expect(result == [day(2025, 1, 31), day(2025, 2, 28), day(2025, 3, 31), day(2025, 4, 30)])
    }

    @Test func yearlyClampsFeb29InNonLeapYears() {
        let sched = schedule(day(2024, 2, 29), .yearly)
        let result = sched.occurrences(in: DateInterval(start: day(2024, 1, 1), end: day(2028, 12, 31)))
        #expect(result == [
            day(2024, 2, 29),  // leap
            day(2025, 2, 28),  // clamped
            day(2026, 2, 28),  // clamped
            day(2027, 2, 28),  // clamped
            day(2028, 2, 29),  // leap again
        ])
    }

    @Test func includesOccurrencesExactlyOnBounds() {
        let sched = schedule(day(2025, 1, 10), .monthly)
        // interval starts AND ends exactly on an occurrence → both included (inclusive bounds)
        let result = sched.occurrences(in: DateInterval(start: day(2025, 1, 10), end: day(2025, 3, 10)))
        #expect(result == [day(2025, 1, 10), day(2025, 2, 10), day(2025, 3, 10)])
    }

    @Test func rangeEntirelyBeforeAnchorIsEmpty() {
        let sched = schedule(day(2025, 6, 1), .monthly)
        let result = sched.occurrences(in: DateInterval(start: day(2025, 1, 1), end: day(2025, 5, 31)))
        #expect(result.isEmpty)
    }

    @Test func futureAnchorOnlyProducesFutureOccurrences() {
        let sched = schedule(day(2025, 6, 1), .monthly)
        let result = sched.occurrences(in: DateInterval(start: day(2025, 1, 1), end: day(2025, 8, 31)))
        #expect(result == [day(2025, 6, 1), day(2025, 7, 1), day(2025, 8, 1)])
    }

    @Test func nextOccurrenceReturnsFirstChargeStrictlyAfter() {
        let sched = schedule(day(2025, 1, 15), .monthly)
        #expect(sched.nextOccurrence(after: day(2025, 1, 20)) == day(2025, 2, 15))
    }

    @Test func nextOccurrenceSkipsAnExactMatch() {
        let sched = schedule(day(2025, 1, 15), .monthly)
        // "after" is strict: asking after an exact occurrence returns the following one
        #expect(sched.nextOccurrence(after: day(2025, 1, 15)) == day(2025, 2, 15))
    }

    @Test func nextOccurrenceBeforeAnchorReturnsAnchor() {
        let sched = schedule(day(2025, 6, 1), .monthly)
        #expect(sched.nextOccurrence(after: day(2025, 1, 1)) == day(2025, 6, 1))
    }
}
