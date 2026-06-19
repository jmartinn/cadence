@testable import Cadence
import Testing

struct AppInfoTests {
    @Test func formatsVersionAndBuild() {
        let info: [String: Any] = ["CFBundleShortVersionString": "1.0", "CFBundleVersion": "1"]
        #expect(AppInfo.versionString(from: info) == "1.0 (1)")
    }

    @Test func omitsBuildWhenMissing() {
        let info: [String: Any] = ["CFBundleShortVersionString": "2.3"]
        #expect(AppInfo.versionString(from: info) == "2.3")
    }

    @Test func fallsBackWhenVersionMissing() {
        #expect(AppInfo.versionString(from: nil) == "—")
        #expect(AppInfo.versionString(from: [:]) == "—")
    }
}
