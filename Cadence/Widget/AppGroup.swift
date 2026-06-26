import Foundation

/// Shared constants for the app↔widget boundary. Compiled into BOTH the app and the widget
/// target so the group id, filename, and widget kind can never drift between them.
enum AppGroup {
    static let identifier = "group.com.jmartinn.Cadence"
    static let snapshotFilename = "next-charges.json"
    /// Must equal the `kind` passed to the widget's `StaticConfiguration` (Task 6).
    static let widgetKind = "NextChargesWidget"

    /// The snapshot file inside the shared container, or nil if the container is unavailable
    /// (e.g. the App Group entitlement is missing).
    static var snapshotURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: identifier)?
            .appendingPathComponent(snapshotFilename)
    }
}
