import Foundation

/// Turns a recurring billing rule (an anchor date + a cycle) into concrete charge dates.
///
/// Pure value type — no SwiftData, no UI — so it unit-tests without a database or simulator state.
public struct BillingSchedule: Sendable {
    public let anchorDate: Date
    public let cycle: BillingCycle

    /// Injected so tests can pin a fixed timezone (UTC) and stay deterministic.
    /// Defaults to the device calendar in production.
    public var calendar: Calendar = .current

    /// Safety bound so a malformed range can never loop forever.
    private static let maxIterations = 10_000

    public init(anchorDate: Date, cycle: BillingCycle, calendar: Calendar = .current) {
        self.anchorDate = anchorDate
        self.cycle = cycle
        self.calendar = calendar
    }

    /// All charge dates within `interval`, inclusive of both bounds.
    ///
    /// Each occurrence is computed from the ORIGINAL `anchorDate` (anchor + n cycles),
    /// never iteratively from the previous result — that's what makes month-end clamping
    /// behave (Jan 31 → Feb 28 → Mar 31, not → Mar 28).
    public func occurrences(in interval: DateInterval) -> [Date] {
        var result: [Date] = []
        for n in 0..<Self.maxIterations {
            guard let date = calendar.date(byAdding: cycle.components(times: n), to: anchorDate) else { break }
            if date > interval.end { break }
            if date >= interval.start { result.append(date) }
        }
        return result
    }

    /// The first charge strictly after `date` (the anchor counts if it's after `date`).
    public func nextOccurrence(after date: Date) -> Date? {
        for n in 0..<Self.maxIterations {
            guard let candidate = calendar.date(byAdding: cycle.components(times: n), to: anchorDate) else { return nil }
            if candidate > date { return candidate }
        }
        return nil
    }
}
