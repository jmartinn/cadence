import Foundation

/// JSON serialization for `WidgetSnapshot`. Sorted keys for diff-stability; `.iso8601` dates
/// (sub-second truncated — fine for billing/anchor dates); `Decimal` kept as a JSON number so
/// money keeps full precision. Mirrors `BackupCodec`.
public enum WidgetSnapshotCodec {
    public static func encode(_ snapshot: WidgetSnapshot) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(snapshot)
    }

    public static func decode(_ data: Data) throws -> WidgetSnapshot {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let snapshot: WidgetSnapshot
        do {
            snapshot = try decoder.decode(WidgetSnapshot.self, from: data)
        } catch {
            throw WidgetSnapshotError.malformed
        }

        guard snapshot.formatVersion <= WidgetSnapshotFormat.currentVersion else {
            throw WidgetSnapshotError.unsupportedVersion(found: snapshot.formatVersion,
                                                         supported: WidgetSnapshotFormat.currentVersion)
        }
        return snapshot
    }
}
