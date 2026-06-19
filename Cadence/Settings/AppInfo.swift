import Foundation

/// Reads the app's marketing version and build number from a bundle info dictionary.
/// Pure (dictionary injected) so it is testable without the real app bundle.
enum AppInfo {
    /// Formats `"<short> (<build>)"`, e.g. `"1.0 (1)"`. Omits the build when absent;
    /// returns an em dash when the short version is missing.
    static func versionString(from info: [String: Any]?) -> String {
        guard let short = info?["CFBundleShortVersionString"] as? String, !short.isEmpty else {
            return "—"
        }
        if let build = info?["CFBundleVersion"] as? String, !build.isEmpty {
            return "\(short) (\(build))"
        }
        return short
    }

    /// The running app's version string, read from `Bundle.main`.
    static var current: String { versionString(from: Bundle.main.infoDictionary) }
}
