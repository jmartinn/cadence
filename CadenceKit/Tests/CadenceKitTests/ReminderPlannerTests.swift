import CadenceKit
import Foundation
import Testing

struct ReminderPlannerTests {
    // MARK: - Deterministic helpers (UTC so tests are timezone-independent)

    let utc: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()

    func day(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 12) -> Date {
        utc.date(from: DateComponents(year: y, month: m, day: d, hour: h))!
    }

    func target(_ name: String, anchor: Date, cycle: BillingCycle = .monthly,
                status: SubscriptionStatus = .active, amount: Decimal = 10) -> ReminderTarget {
        ReminderTarget(id: name, name: name,
                       plan: SubscriptionPlan(amount: amount, cycle: cycle,
                                              anchorDate: anchor, status: status))
    }

    func horizon(from now: Date, months: Int = 6) -> DateInterval {
        DateInterval(start: now, end: utc.date(byAdding: .month, value: months, to: now)!)
    }

    /// Simple test formatter so we don't depend on app-side PriceText/locale.
    let fmt: (Decimal) -> String = { "€\(NSDecimalNumber(decimal: $0).stringValue)" }

    func plan(_ targets: [ReminderTarget], _ lead: ReminderLeadTime, now: Date,
              cap: Int = 60) -> [ReminderRequest] {
        ReminderPlanner.requests(for: targets, leadTime: lead, now: now,
                                 horizon: horizon(from: now), cap: cap,
                                 calendar: utc, formatAmount: fmt)
    }

    // MARK: - Lead-time subtraction & fire time

    @Test func oneDayLeadFiresTheDayBeforeAtNineAM() {
        let now = day(2025, 6, 1, 0)
        let reqs = plan([target("Netflix", anchor: day(2025, 6, 15))], .oneDay, now: now)
        let first = reqs.first!
        #expect(utc.dateComponents([.year, .month, .day], from: first.fireDate)
            == DateComponents(year: 2025, month: 6, day: 14))
        #expect(utc.component(.hour, from: first.fireDate) == 9)
        #expect(utc.component(.minute, from: first.fireDate) == 0)
    }

    @Test func sameDayLeadFiresOnTheChargeDay() {
        let now = day(2025, 6, 1, 0)
        let reqs = plan([target("Spotify", anchor: day(2025, 6, 15))], .sameDay, now: now)
        #expect(utc.dateComponents([.year, .month, .day], from: reqs.first!.fireDate)
            == DateComponents(year: 2025, month: 6, day: 15))
    }

    // MARK: - Month-end clamping carried through from BillingSchedule

    @Test func monthEndClampingCarriesThrough() {
        let now = day(2025, 1, 1, 0)
        // Jan 31 monthly → Feb 28 occurrence → with .oneDay lead the Feb reminder is Feb 27.
        let reqs = plan([target("Gym", anchor: day(2025, 1, 31))], .oneDay, now: now)
        let febFire = reqs.first { utc.component(.month, from: $0.fireDate) == 2 }!
        #expect(utc.dateComponents([.year, .month, .day], from: febFire.fireDate)
            == DateComponents(year: 2025, month: 2, day: 27))
    }

    // MARK: - Horizon & past filtering

    @Test func nothingBeyondHorizon() {
        let now = day(2025, 1, 1, 0)
        // monthly over a 6-month horizon → at most ~6-7 occurrences, never 12.
        let reqs = plan([target("News", anchor: day(2025, 1, 10))], .oneDay, now: now)
        #expect(reqs.count <= 7)
        #expect(reqs.allSatisfy { $0.fireDate <= self.horizon(from: now).end })
    }

    @Test func pastFireDatesAreDropped() {
        // now is AFTER the day-before-the-15th reminder, so the June one is gone; July remains.
        let now = day(2025, 6, 20, 0)
        let reqs = plan([target("Netflix", anchor: day(2025, 6, 15))], .oneDay, now: now)
        #expect(reqs.allSatisfy { $0.fireDate > now })
        #expect(reqs.contains { utc.component(.month, from: $0.fireDate) == 7 })
        #expect(!reqs.contains { utc.component(.month, from: $0.fireDate) == 6 })
    }

    // MARK: - Cap

    @Test func capKeepsTheSoonestAndNeverExceeds() {
        let now = day(2025, 1, 1, 0)
        // 20 monthly subs × ~6 occurrences each ≈ 120 candidates; cap to 10.
        let targets = (0..<20).map { target("S\($0)", anchor: day(2025, 1, 5 + ($0 % 20))) }
        let reqs = plan(targets, .oneDay, now: now, cap: 10)
        #expect(reqs.count == 10)
        // Sorted ascending by fireDate.
        #expect(reqs == reqs.sorted { $0.fireDate < $1.fireDate })
        // And they are the 10 soonest: nothing dropped fires earlier than the last kept.
        let full = plan(targets, .oneDay, now: now, cap: .max)
        #expect(reqs == Array(full.prefix(10)))
    }

    // MARK: - Scope & totality

    @Test func onlyActiveTargetsProduceRequests() {
        let now = day(2025, 6, 1, 0)
        let reqs = plan([
            target("Paused", anchor: day(2025, 6, 15), status: .paused),
            target("Ended", anchor: day(2025, 6, 15), status: .ended),
        ], .oneDay, now: now)
        #expect(reqs.isEmpty)
    }

    @Test func emptyInputProducesEmptyOutput() {
        #expect(plan([], .oneDay, now: day(2025, 6, 1, 0)).isEmpty)
    }

    // MARK: - Content

    @Test func contentUsesNamePhraseAndFormattedAmount() {
        let now = day(2025, 6, 1, 0)
        let reqs = plan([target("Netflix", anchor: day(2025, 6, 15), amount: Decimal(string: "17.99")!)],
                        .oneDay, now: now)
        let r = reqs.first!
        #expect(r.title == "Netflix renews tomorrow")
        #expect(r.body == "€17.99 will be charged.")
        #expect(r.id.hasPrefix("cadence.reminder."))
    }
}
