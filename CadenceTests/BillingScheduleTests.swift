import Testing
import Foundation
@testable import Cadence

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
}
