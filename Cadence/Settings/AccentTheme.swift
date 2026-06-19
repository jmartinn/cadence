import SwiftUI

/// The app's single user-customizable accent, applied app-wide via `.tint` at the root.
/// Curated to Apple system colors so each option adapts to light/dark and is contrast-vetted
/// for free. The `rawValue` strings are a persistence contract (stored in `@AppStorage`) —
/// never change them, or saved preferences break.
enum AccentTheme: String, CaseIterable, Identifiable {
    case blue, indigo, purple, pink, red, orange, green, teal

    /// The accent used until the user picks one. Matches the iOS-native blue accent.
    static let `default`: AccentTheme = .blue

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .blue: .blue
        case .indigo: .indigo
        case .purple: .purple
        case .pink: .pink
        case .red: .red
        case .orange: .orange
        case .green: .green
        case .teal: .teal
        }
    }

    var displayName: String {
        switch self {
        case .blue: "Blue"
        case .indigo: "Indigo"
        case .purple: "Purple"
        case .pink: "Pink"
        case .red: "Red"
        case .orange: "Orange"
        case .green: "Green"
        case .teal: "Teal"
        }
    }
}

extension AccentTheme {
    /// The `@AppStorage`/UserDefaults key under which the chosen accent is persisted.
    /// Single source of truth for the key — referenced by both the root tint and the picker.
    static let storageKey = "accentTheme"
}
