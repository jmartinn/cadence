@testable import Cadence
import Foundation
import Testing

struct CalendarDayTapTests {
    private func sub(_ name: String) -> Subscription {
        Subscription(name: name, amount: 9, billingCycle: .monthly,
                     anchorDate: .distantPast, status: .active, category: "T")
    }

    private func day(markers: [MonthCalendar.Marker], isInMonth: Bool = true) -> MonthCalendar.Day {
        MonthCalendar.Day(date: .distantPast, isInMonth: isInMonth, isToday: false, markers: markers)
    }

    private func marker(_ s: Subscription) -> MonthCalendar.Marker {
        MonthCalendar.Marker(serviceName: s.name, hasCard: false, subscription: s)
    }

    @Test func noMarkersIsNone() {
        #expect(CalendarDayTap.outcome(for: day(markers: [])) == .none)
    }

    @Test func paddingCellIsNone() {
        #expect(CalendarDayTap.outcome(for: day(markers: [], isInMonth: false)) == .none)
    }

    @Test func singleChargeIsDetail() {
        let netflix = sub("Netflix")
        #expect(CalendarDayTap.outcome(for: day(markers: [marker(netflix)])) == .detail(netflix))
    }

    @Test func multipleChargesIsDisambiguate() {
        let a = sub("A"); let b = sub("B")
        let outcome = CalendarDayTap.outcome(for: day(markers: [marker(a), marker(b)]))
        #expect(outcome == .disambiguate([a, b]))   // order preserved
    }
}
