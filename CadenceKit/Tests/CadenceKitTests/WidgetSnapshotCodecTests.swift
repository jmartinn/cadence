import CadenceKit
import Foundation
import Testing

struct WidgetSnapshotCodecTests {
    // Whole-second dates round-trip exactly under .iso8601 (sub-second is truncated).
    let d1 = Date(timeIntervalSince1970: 1_000_000)
    let d2 = Date(timeIntervalSince1970: 1_700_000_000)

    func sample() -> WidgetSnapshot {
        WidgetSnapshot(generatedAt: d2, entries: [
            WidgetSnapshot.Entry(name: "Netflix", serviceKey: "netflix",
                                 amount: Decimal(string: "12.99")!, billingCycle: .monthly,
                                 anchorDate: d1, status: .active),
            WidgetSnapshot.Entry(name: "Amazon Prime", serviceKey: nil,
                                 amount: Decimal(string: "49.99")!, billingCycle: .yearly,
                                 anchorDate: d2, status: .paused),
        ])
    }

    @Test func roundTripPreservesEveryField() throws {
        let snap = sample()
        let decoded = try WidgetSnapshotCodec.decode(WidgetSnapshotCodec.encode(snap))
        #expect(decoded == snap)
    }

    @Test func decimalPrecisionIsPreserved() throws {
        let decoded = try WidgetSnapshotCodec.decode(WidgetSnapshotCodec.encode(sample()))
        #expect(decoded.entries[0].amount == Decimal(string: "12.99")!)
    }

    @Test func emptySnapshotRoundTrips() throws {
        let snap = WidgetSnapshot(generatedAt: d1, entries: [])
        let decoded = try WidgetSnapshotCodec.decode(WidgetSnapshotCodec.encode(snap))
        #expect(decoded == snap)
    }

    @Test func malformedDataThrows() {
        #expect(throws: WidgetSnapshotError.malformed) {
            _ = try WidgetSnapshotCodec.decode(Data("not json".utf8))
        }
    }

    @Test func newerFormatVersionThrowsUnsupported() throws {
        var snap = sample()
        snap.formatVersion = WidgetSnapshotFormat.currentVersion + 1
        let data = try WidgetSnapshotCodec.encode(snap)
        #expect(throws: WidgetSnapshotError.unsupportedVersion(
            found: WidgetSnapshotFormat.currentVersion + 1,
            supported: WidgetSnapshotFormat.currentVersion
        )) {
            _ = try WidgetSnapshotCodec.decode(data)
        }
    }
}
