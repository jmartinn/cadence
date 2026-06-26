import CadenceKit
import Foundation
import Testing

struct UpcomingChargePlannerTests {
    /// UTC calendar so charge dates are deterministic regardless of the test machine.
    var utc: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }

    let now = Date(timeIntervalSince1970: 1_700_000_000) // 2023-11-14T22:13:20Z

    func entry(_ name: String, _ key: String?, _ amount: String, _ cycle: BillingCycle,
               anchor: Date, status: SubscriptionStatus = .active) -> WidgetSnapshot.Entry {
        WidgetSnapshot.Entry(name: name, serviceKey: key, amount: Decimal(string: amount)!,
                             billingCycle: cycle, anchorDate: anchor, status: status)
    }

    @Test func sortsSoonestFirst() {
        let soon = entry("Soon", "a", "1.00", .monthly, anchor: now.addingTimeInterval(2 * 86_400))
        let later = entry("Later", "b", "2.00", .monthly, anchor: now.addingTimeInterval(10 * 86_400))
        let result = UpcomingChargePlanner.upcoming(from: [later, soon], now: now, limit: 10, calendar: utc)
        #expect(result.map(\.name) == ["Soon", "Later"])
    }

    @Test func truncatesToLimit() {
        let entries = (1...5).map {
            entry("S\($0)", nil, "1.00", .monthly, anchor: now.addingTimeInterval(Double($0) * 86_400))
        }
        let result = UpcomingChargePlanner.upcoming(from: entries, now: now, limit: 3, calendar: utc)
        #expect(result.count == 3)
        #expect(result.map(\.name) == ["S1", "S2", "S3"])
    }

    @Test func skipsNonActive() {
        let paused = entry("Paused", nil, "1.00", .monthly, anchor: now.addingTimeInterval(86_400), status: .paused)
        let ended = entry("Ended", nil, "1.00", .monthly, anchor: now.addingTimeInterval(86_400), status: .ended)
        let active = entry("Active", nil, "1.00", .monthly, anchor: now.addingTimeInterval(86_400))
        let result = UpcomingChargePlanner.upcoming(from: [paused, ended, active], now: now, limit: 10, calendar: utc)
        #expect(result.map(\.name) == ["Active"])
    }

    @Test func carriesNameKeyAmount() {
        let e = entry("Netflix", "netflix", "12.99", .monthly, anchor: now.addingTimeInterval(86_400))
        let result = UpcomingChargePlanner.upcoming(from: [e], now: now, limit: 10, calendar: utc)
        let charge = try! #require(result.first)
        #expect(charge.name == "Netflix")
        #expect(charge.serviceKey == "netflix")
        #expect(charge.amount == Decimal(string: "12.99")!)
        #expect(charge.date > now)
    }

    @Test func emptyInputYieldsEmpty() {
        #expect(UpcomingChargePlanner.upcoming(from: [], now: now, limit: 10, calendar: utc).isEmpty)
    }

    @Test func futureAnchorCountsAsItsOwnFirstCharge() {
        // A charge whose anchor is in the future is itself the next occurrence.
        let future = now.addingTimeInterval(5 * 86_400)
        let e = entry("Future", nil, "1.00", .yearly, anchor: future)
        let result = UpcomingChargePlanner.upcoming(from: [e], now: now, limit: 10, calendar: utc)
        #expect(result.first?.date == future)
    }
}
