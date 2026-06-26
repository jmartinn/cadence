import Foundation

/// JSON serialization for `BackupDocument`. Pretty-printed + sorted keys so the file is
/// human-readable and diff-stable. Dates are ISO-8601 (readable; sub-second precision is
/// truncated, which is fine for billing/anchor dates). `Decimal` is encoded as a JSON number
/// and decoded straight back to `Decimal`, so money keeps full precision.
public enum BackupCodec {
    public static func encode(_ document: BackupDocument) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(document)
    }

    public static func decode(_ data: Data) throws -> BackupDocument {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let document: BackupDocument
        do {
            document = try decoder.decode(BackupDocument.self, from: data)
        } catch {
            throw BackupError.malformed
        }

        guard document.formatVersion <= BackupFormat.currentVersion else {
            throw BackupError.unsupportedVersion(found: document.formatVersion,
                                                 supported: BackupFormat.currentVersion)
        }
        return document
    }
}
