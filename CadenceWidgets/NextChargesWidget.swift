import CadenceKit
import SwiftUI
import WidgetKit

/// One timeline point: the charges to show, rendered relative to `date`.
struct NextChargesEntry: TimelineEntry {
    let date: Date
    let charges: [UpcomingCharge]
}

/// Reads the App Group snapshot, computes upcoming charges, and emits a short daily countdown
/// timeline that re-requests once the soonest charge has passed (or after a week for distant ones).
struct NextChargesProvider: TimelineProvider {
    /// Enough for the medium list plus a little headroom.
    private static let limit = 4
    /// Daily countdown entries before WidgetKit asks for a fresh timeline.
    private static let countdownDays = 7

    func placeholder(in _: Context) -> NextChargesEntry {
        NextChargesEntry(date: Date(), charges: Self.sample)
    }

    func getSnapshot(in _: Context, completion: @escaping (NextChargesEntry) -> Void) {
        let now = Date()
        // Gallery preview: real data if present, else realistic sample (HIG: realistic preview).
        completion(NextChargesEntry(date: now, charges: load(now: now) ?? Self.sample))
    }

    func getTimeline(in _: Context, completion: @escaping (Timeline<NextChargesEntry>) -> Void) {
        let now = Date()
        let charges = load(now: now) ?? []
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: now)
        let lastDay = charges.first.map { calendar.startOfDay(for: $0.date) }

        var entries: [NextChargesEntry] = []
        for offset in 0...Self.countdownDays {
            guard let day = calendar.date(byAdding: .day, value: offset, to: startOfToday) else { break }
            if let lastDay, day > lastDay { break } // stop once the soonest charge has elapsed
            entries.append(NextChargesEntry(date: max(day, now), charges: charges))
        }
        if entries.isEmpty { entries = [NextChargesEntry(date: now, charges: charges)] }

        completion(Timeline(entries: entries, policy: .atEnd))
    }

    /// Decode the snapshot and compute upcoming charges, or nil if there's no readable file yet.
    private func load(now: Date) -> [UpcomingCharge]? {
        guard let url = AppGroup.snapshotURL,
              let data = try? Data(contentsOf: url),
              let snapshot = try? WidgetSnapshotCodec.decode(data) else { return nil }
        return UpcomingChargePlanner.upcoming(from: snapshot.entries, now: now, limit: Self.limit)
    }

    /// Realistic sample for the gallery preview only.
    static let sample: [UpcomingCharge] = [
        UpcomingCharge(name: "Netflix", serviceKey: "netflix",
                       amount: Decimal(string: "12.99")!, date: Date().addingTimeInterval(3 * 86_400)),
        UpcomingCharge(name: "Spotify", serviceKey: "spotify",
                       amount: Decimal(string: "10.99")!, date: Date().addingTimeInterval(5 * 86_400)),
        UpcomingCharge(name: "iCloud+", serviceKey: "icloud",
                       amount: Decimal(string: "2.99")!, date: Date().addingTimeInterval(8 * 86_400)),
    ]
}

struct NextChargesWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: AppGroup.widgetKind, provider: NextChargesProvider()) { entry in
            NextChargesEntryView(entry: entry)
                .widgetURL(URL(string: "cadence://home"))
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Upcoming Charges")
        .description("See your subscriptions' next charges at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
