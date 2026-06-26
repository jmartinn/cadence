@testable import Cadence
import CadenceKit
import Foundation
import SwiftData
import Testing

struct WidgetSnapshotWriterTests {
    let container = CadenceStore.inMemory()
    let stamp = Date(timeIntervalSince1970: 1_700_000_000)

    @Test func snapshotMapsEveryFieldForAllSubscriptions() throws {
        let context = ModelContext(container)
        context.insert(Subscription(
            name: "Netflix", amount: Decimal(string: "12.99")!, billingCycle: .monthly,
            anchorDate: Date(timeIntervalSince1970: 1_000_000), status: .active,
            category: "Entertainment", serviceKey: "netflix"
        ))
        context.insert(Subscription(
            name: "Old Gym", amount: Decimal(string: "30.00")!, billingCycle: .monthly,
            anchorDate: Date(timeIntervalSince1970: 1_000_000), status: .ended,
            category: "Health", serviceKey: nil
        ))
        try context.save()

        let snap = try WidgetSnapshotWriter.snapshot(from: context, generatedAt: stamp)
        #expect(snap.formatVersion == WidgetSnapshotFormat.currentVersion)
        #expect(snap.generatedAt == stamp)
        // Faithful mirror: BOTH the active and the ended sub are present (planner filters later).
        #expect(snap.entries.count == 2)
        let netflix = try #require(snap.entries.first { $0.name == "Netflix" })
        #expect(netflix.serviceKey == "netflix")
        #expect(netflix.amount == Decimal(string: "12.99")!)
        #expect(netflix.billingCycle == .monthly)
        #expect(netflix.anchorDate == Date(timeIntervalSince1970: 1_000_000))
        #expect(netflix.status == .active)
        let gym = try #require(snap.entries.first { $0.name == "Old Gym" })
        #expect(gym.status == .ended)
        #expect(gym.serviceKey == nil)
    }

    @Test func snapshotIsEmptyForEmptyStore() throws {
        let context = ModelContext(container)
        let snap = try WidgetSnapshotWriter.snapshot(from: context, generatedAt: stamp)
        #expect(snap.entries.isEmpty)
    }

    @Test func snapshotRoundTripsThroughCodec() throws {
        let context = ModelContext(container)
        context.insert(Subscription(
            name: "Spotify", amount: Decimal(string: "10.99")!, billingCycle: .monthly,
            anchorDate: Date(timeIntervalSince1970: 1_000_000), status: .active, category: "Music"
        ))
        try context.save()

        let snap = try WidgetSnapshotWriter.snapshot(from: context, generatedAt: stamp)
        let decoded = try WidgetSnapshotCodec.decode(WidgetSnapshotCodec.encode(snap))
        #expect(decoded == snap)
    }
}
