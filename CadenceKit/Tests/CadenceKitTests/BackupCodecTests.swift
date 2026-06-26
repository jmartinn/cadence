import CadenceKit
import Foundation
import Testing

struct BackupCodecTests {
    // Whole-second dates round-trip exactly under .iso8601 (sub-second is truncated).
    let d1 = Date(timeIntervalSince1970: 1_000_000)
    let d2 = Date(timeIntervalSince1970: 1_700_000_000)

    func sampleDocument() -> BackupDocument {
        let parent = BackupSubscription(
            id: UUID(uuidString: "00000000-0000-0000-0000-0000000000A1")!,
            name: "Amazon Prime", amount: Decimal(string: "14.99")!, billingCycle: .yearly,
            anchorDate: d1, status: .active, category: "Shopping",
            serviceKey: "amazon-prime", paymentBrand: "Visa", paymentLast4: "4821",
            parentID: nil
        )
        let child = BackupSubscription(
            id: UUID(uuidString: "00000000-0000-0000-0000-0000000000B2")!,
            name: "Paramount+", amount: Decimal(string: "7.99")!, billingCycle: .monthly,
            anchorDate: d2, status: .paused, category: "Entertainment",
            serviceKey: nil, paymentBrand: nil, paymentLast4: nil,
            parentID: parent.id
        )
        return BackupDocument(
            exportedAt: d2, appVersion: "1.0 (1)",
            subscriptions: [parent, child],
            anchor: BackupAnchor(balance: Decimal(string: "1025.06")!, asOfDate: d1,
                                 monthlyIncome: Decimal(string: "2000.00")!, incomePayday: .distantPast)
        )
    }

    @Test func roundTripPreservesEveryField() throws {
        let doc = sampleDocument()
        let decoded = try BackupCodec.decode(BackupCodec.encode(doc))
        #expect(decoded == doc)
    }

    @Test func decimalPrecisionIsPreserved() throws {
        let doc = sampleDocument()
        let decoded = try BackupCodec.decode(BackupCodec.encode(doc))
        #expect(decoded.subscriptions[0].amount == Decimal(string: "14.99")!)
        #expect(decoded.anchor?.balance == Decimal(string: "1025.06")!)
    }

    @Test func addOnLinkageSurvivesViaParentID() throws {
        let doc = sampleDocument()
        let decoded = try BackupCodec.decode(BackupCodec.encode(doc))
        let parentID = decoded.subscriptions[0].id
        #expect(decoded.subscriptions[0].parentID == nil)
        #expect(decoded.subscriptions[1].parentID == parentID)
    }

    @Test func emptyDocumentRoundTrips() throws {
        let doc = BackupDocument(exportedAt: d1, appVersion: nil, subscriptions: [], anchor: nil)
        let decoded = try BackupCodec.decode(BackupCodec.encode(doc))
        #expect(decoded == doc)
    }

    @Test func newerFormatVersionThrowsUnsupported() throws {
        var doc = sampleDocument()
        doc.formatVersion = BackupFormat.currentVersion + 1
        let data = try BackupCodec.encode(doc)
        #expect(throws: BackupError.unsupportedVersion(found: BackupFormat.currentVersion + 1,
                                                       supported: BackupFormat.currentVersion)) {
            try BackupCodec.decode(data)
        }
    }

    @Test func garbageBytesThrowMalformed() {
        let data = Data("not json".utf8)
        #expect(throws: BackupError.malformed) { try BackupCodec.decode(data) }
    }
}
