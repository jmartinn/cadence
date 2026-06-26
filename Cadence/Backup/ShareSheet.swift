import SwiftUI
import UIKit

/// Minimal UIKit bridge to present the system share sheet (`UIActivityViewController`) for a
/// file URL. SwiftUI's `ShareLink` can't share a file that is produced lazily on tap, so we
/// present this via `.sheet(item:)` once the export file exists.
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context _: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_: UIActivityViewController, context _: Context) {}
}
