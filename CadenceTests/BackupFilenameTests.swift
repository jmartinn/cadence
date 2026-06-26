@testable import Cadence
import Foundation
import Testing

struct BackupFilenameTests {
    @Test func filenameUsesIsoDateAndJsonExtension() {
        // 2026-06-26 12:00:00 UTC
        let date = Date(timeIntervalSince1970: 1_782_475_200)
        let name = BackupService.suggestedFilename(for: date)
        #expect(name == "Cadence-Backup-2026-06-26.json")
    }
}
