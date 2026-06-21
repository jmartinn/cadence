import CadenceKit
import SwiftData
import SwiftUI
import UIKit

/// Navigation token for pushing Settings onto the Home navigation stack.
enum SettingsRoute: Hashable { case settings }

/// The pushed Settings screen: renewal reminders, accent customization, and app version.
/// Reached from the Home header's profile button.
struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage(ReminderDefaults.enabledKey) private var remindersEnabled = false
    @AppStorage(ReminderDefaults.leadTimeKey) private var leadTime: ReminderLeadTime = .oneDay
    @State private var permissionDenied = false

    private let coordinator = ReminderCoordinator()

    var body: some View {
        List {
            Section {
                Toggle("Renewal reminders", isOn: $remindersEnabled)
                if remindersEnabled {
                    Picker("Remind me", selection: $leadTime) {
                        ForEach(ReminderLeadTime.allCases) { lead in
                            Text(lead.displayName).tag(lead)
                        }
                    }
                }
            } header: {
                Text("Reminders")
            } footer: {
                if permissionDenied {
                    VStack(alignment: .leading, spacing: Space.xs) {
                        Text("Notifications are turned off for Cadence. Enable them in Settings to get renewal reminders.")
                        Button("Open Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                    }
                } else {
                    Text("Get a heads-up before each subscription renews.")
                }
            }

            Section("Appearance") {
                AccentSwatchPicker()
            }

            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(AppInfo.current)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .task { await refreshPermissionState() }
        .onChange(of: remindersEnabled) { _, enabled in
            Task { await handleToggle(enabled) }
        }
        .onChange(of: leadTime) { _, _ in
            Task { await coordinator.reschedule(context: modelContext) }
        }
    }

    /// Reflect the real system permission state in the denied banner.
    private func refreshPermissionState() async {
        let status = await coordinator.scheduler.authorizationStatus()
        permissionDenied = remindersEnabled && status == .denied
    }

    /// On enable: request authorization just-in-time. On disable: cancel everything.
    private func handleToggle(_ enabled: Bool) async {
        if enabled {
            let status = await coordinator.scheduler.authorizationStatus()
            if status == .notDetermined {
                _ = await coordinator.scheduler.requestAuthorization()
            }
            permissionDenied = await coordinator.scheduler.authorizationStatus() == .denied
        } else {
            permissionDenied = false
        }
        await coordinator.reschedule(context: modelContext)
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        SettingsView()
    }
}
#endif
