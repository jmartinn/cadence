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
    @State private var exportFile: ExportFile?
    @State private var dataError: String?

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

            Section {
                Button("Export Backup") { exportBackup() }
            } header: {
                Text("Data")
            } footer: {
                Text("Save a copy of your subscriptions and balance to share or store.")
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
        .sheet(item: $exportFile) { file in
            ShareSheet(items: [file.url])
        }
        .alert("Backup failed", isPresented: Binding(
            get: { dataError != nil },
            set: { if !$0 { dataError = nil } }
        )) {
            Button("OK", role: .cancel) { dataError = nil }
        } message: {
            Text(dataError ?? "")
        }
    }

    /// Reflect the real system permission state in the denied banner.
    private func refreshPermissionState() async {
        let status = await coordinator.scheduler.authorizationStatus()
        permissionDenied = remindersEnabled && status == .denied
    }

    /// Build the backup file and present the system share sheet for it.
    private func exportBackup() {
        do {
            let document = try BackupService.export(from: modelContext)
            let data = try BackupCodec.encode(document)
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent(BackupService.suggestedFilename())
            try data.write(to: url, options: .atomic)
            exportFile = ExportFile(url: url)
        } catch {
            dataError = "Couldn't create the backup."
        }
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

/// Wraps the temp export URL so `.sheet(item:)` can present the share sheet for it.
private struct ExportFile: Identifiable {
    let id = UUID()
    let url: URL
}

#if DEBUG
#Preview {
    NavigationStack {
        SettingsView()
    }
}
#endif
