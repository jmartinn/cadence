import Foundation
import SwiftData
import WidgetKit

/// Rewrites the widget snapshot and asks WidgetKit to reload. Best-effort: a failed write must
/// never break the user flow it's attached to, so errors are swallowed (the widget keeps its last
/// good snapshot). Call this from every data-mutation path — the same ones that reschedule
/// reminders, EXCEPT reminder-only setting changes (lead time / enable toggle).
@MainActor
enum WidgetRefresher {
    static func refresh(context: ModelContext) {
        do {
            try WidgetSnapshotWriter.write(from: context)
            WidgetCenter.shared.reloadTimelines(ofKind: AppGroup.widgetKind)
        } catch {
            // best-effort; keep the last good snapshot
        }
    }
}
