import CadenceKit
import Foundation
import SwiftData

/// App-side SwiftData boundary for the widget snapshot. `snapshot(from:)` is the pure, testable
/// mapping; `write(from:)` adds the side effect of persisting to the shared container.
enum WidgetSnapshotWriter {
    /// Map every `@Model Subscription` to a portable snapshot entry (faithful mirror, including
    /// `.paused`/`.ended` — the planner filters to active). No file IO; unit-tested.
    static func snapshot(from context: ModelContext, generatedAt: Date = .now) throws -> WidgetSnapshot {
        let subscriptions = try context.fetch(FetchDescriptor<Subscription>())
        let entries = subscriptions.map { sub in
            WidgetSnapshot.Entry(
                name: sub.name,
                serviceKey: sub.serviceKey,
                amount: sub.amount,
                billingCycle: sub.billingCycle,
                anchorDate: sub.anchorDate,
                status: sub.status
            )
        }
        return WidgetSnapshot(generatedAt: generatedAt, entries: entries)
    }

    /// Build the snapshot and write it atomically to the App Group container.
    @discardableResult
    static func write(from context: ModelContext, generatedAt: Date = .now) throws -> WidgetSnapshot {
        let snapshot = try snapshot(from: context, generatedAt: generatedAt)
        guard let url = AppGroup.snapshotURL else { throw WidgetSnapshotWriterError.noContainer }
        try WidgetSnapshotCodec.encode(snapshot).write(to: url, options: .atomic)
        return snapshot
    }
}

/// Why a snapshot could not be written.
enum WidgetSnapshotWriterError: Error {
    case noContainer
}
