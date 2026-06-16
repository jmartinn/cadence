@testable import Cadence
import Foundation
import Testing

struct MonthCalendarTests {
    private var utc: Calendar {
        var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(identifier: "UTC")!; return c
    }

    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        utc.date(from: DateComponents(year: y, month: m, day: d))!
    }

    private func sub(_ name: String, day: Int, status: SubscriptionStatus = .active, card: Bool = false) -> Subscription {
        Subscription(name: name, amount: 9, billingCycle: .monthly, anchorDate: date(2025, 12, day),
                     status: status, category: "T",
                     paymentBrand: card ? "Visa" : nil, paymentLast4: card ? "4821" : nil)
    }

    private func days(_ weeks: [MonthCalendar.Week]) -> [MonthCalendar.Day] { weeks.flatMap(\.days) }

    @Test func gridIsMondayFirstAndStartsOnDec1() {
        let weeks = MonthCalendar.weeks(for: date(2025, 12, 1), subscriptions: [], today: date(2025, 12, 11), calendar: utc)
        // Dec 1 2025 is a Monday → no leading padding; 31 days → 5 rows of 7
        #expect(weeks.count == 5)
        #expect(weeks.first?.days.count == 7)
        let first = try! #require(weeks.first?.days.first)
        #expect(utc.component(.day, from: first.date) == 1)
        #expect(first.isInMonth)
    }

    @Test func todayIsMarked() {
        let weeks = MonthCalendar.weeks(for: date(2025, 12, 1), subscriptions: [], today: date(2025, 12, 11), calendar: utc)
        let today = days(weeks).first { $0.isToday }
        #expect(today != nil)
        #expect(utc.component(.day, from: today!.date) == 11)
    }

    @Test func chargeAttachesMarkerWithCardFlag() {
        let netflix = sub("Netflix", day: 4, card: true)
        let weeks = MonthCalendar.weeks(for: date(2025, 12, 1),
                                        subscriptions: [netflix],
                                        today: date(2025, 12, 11), calendar: utc)
        let dec4 = days(weeks).first { $0.isInMonth && utc.component(.day, from: $0.date) == 4 }
        let marker = try! #require(dec4?.markers.first)
        #expect(marker.serviceName == "Netflix")
        #expect(marker.hasCard == true)
        #expect(marker.subscription === netflix)   // identity carried through
    }

    @Test func eachChargeCarriesItsOwnSubscription() {
        let a = sub("A", day: 8)
        let b = sub("B", day: 8)
        let weeks = MonthCalendar.weeks(for: date(2025, 12, 1),
                                        subscriptions: [a, b],
                                        today: date(2025, 12, 11), calendar: utc)
        let dec8 = days(weeks).first { $0.isInMonth && utc.component(.day, from: $0.date) == 8 }
        #expect(dec8?.markers.map(\.subscription).count == 2)
        #expect(dec8?.markers.contains(where: { $0.subscription === a }) == true)
        #expect(dec8?.markers.contains(where: { $0.subscription === b }) == true)
    }

    @Test func noCardMeansNoBadge() {
        let weeks = MonthCalendar.weeks(for: date(2025, 12, 1),
                                        subscriptions: [sub("Notion", day: 23, card: false)],
                                        today: date(2025, 12, 11), calendar: utc)
        let dec23 = days(weeks).first { $0.isInMonth && utc.component(.day, from: $0.date) == 23 }
        #expect(dec23?.markers.first?.hasCard == false)
    }

    @Test func multipleChargesSameDayProduceMultipleMarkers() {
        let weeks = MonthCalendar.weeks(for: date(2025, 12, 1),
                                        subscriptions: [sub("A", day: 8), sub("B", day: 8)],
                                        today: date(2025, 12, 11), calendar: utc)
        let dec8 = days(weeks).first { $0.isInMonth && utc.component(.day, from: $0.date) == 8 }
        #expect(dec8?.markers.count == 2)
    }

    @Test func monthStartingMidWeekHasLeadingPaddingAndIsMondayFirst() {
        // March 2025 begins on a Saturday → Monday-first leading offset = 5,
        // and 31 days → ceil((5 + 31) / 7) = 6 rows / 42 cells. This exercises
        // the (weekday + 5) % 7 offset, the leading/trailing padding, and the
        // isInMonth == false marker guard — none of which the Dec 2025 tests hit.
        let march = date(2025, 3, 1)
        // Charges whose day-number also appears among the padding cells:
        // leading padding is Feb 24–28, trailing padding is Apr 1–6.
        let onThe28th = Subscription(name: "Spotify", amount: 9, billingCycle: .monthly,
                                     anchorDate: date(2025, 3, 28), status: .active, category: "T")
        let onThe1st = Subscription(name: "iCloud", amount: 9, billingCycle: .monthly,
                                    anchorDate: date(2025, 3, 1), status: .active, category: "T")
        let weeks = MonthCalendar.weeks(for: march, subscriptions: [onThe28th, onThe1st],
                                        today: date(2025, 3, 15), calendar: utc)
        let all = days(weeks)

        #expect(weeks.count == 6)
        #expect(all.count == 42)

        // First cell is the correct prior-month date (Feb 24 2025) and is padding.
        let first = try! #require(all.first)
        #expect(first.isInMonth == false)
        #expect(utc.component(.month, from: first.date) == 2)
        #expect(utc.component(.day, from: first.date) == 24)

        // 5 leading padding cells, then 31 in-month days, then 6 trailing padding cells.
        #expect(all.prefix(5).allSatisfy { !$0.isInMonth })
        #expect(all.filter(\.isInMonth).count == 31)
        #expect(all.suffix(6).allSatisfy { !$0.isInMonth })

        // Every padding cell carries no markers — even Feb 28 / Apr 1, which share a
        // day-number with a charge (the isInMonth ? ... : [] guard holds).
        #expect(all.filter { !$0.isInMonth }.allSatisfy { $0.markers.isEmpty })

        // The in-month charges still attach to the correct days.
        let mar1 = all.first { $0.isInMonth && utc.component(.day, from: $0.date) == 1 }
        let mar28 = all.first { $0.isInMonth && utc.component(.day, from: $0.date) == 28 }
        #expect(mar1?.markers.map(\.serviceName) == ["iCloud"])
        #expect(mar28?.markers.map(\.serviceName) == ["Spotify"])
    }

    @Test func pausedAndEndedSubsContributeNoMarkers() {
        let weeks = MonthCalendar.weeks(for: date(2025, 12, 1),
                                        subscriptions: [sub("P", day: 5, status: .paused), sub("E", day: 6, status: .ended)],
                                        today: date(2025, 12, 11), calendar: utc)
        #expect(days(weeks).allSatisfy { $0.markers.isEmpty })
    }
}
