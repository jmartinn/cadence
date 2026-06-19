import SwiftUI

/// Navigation token for pushing Settings onto the Home navigation stack.
enum SettingsRoute: Hashable { case settings }

/// The pushed Settings screen: accent customization + app version.
/// Reached from the Home header's profile button.
struct SettingsView: View {
    var body: some View {
        List {
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
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        SettingsView()
    }
}
#endif
