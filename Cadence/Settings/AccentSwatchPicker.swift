import SwiftUI

/// Horizontal, scrollable row of accent swatches. Binds to the persisted accent
/// (`@AppStorage(AccentTheme.storageKey)`); selecting one re-tints the whole app live via the root tint.
struct AccentSwatchPicker: View {
    @AppStorage(AccentTheme.storageKey) private var selection: AccentTheme = .default

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Space.md) {
                ForEach(AccentTheme.allCases) { theme in
                    Button { selection = theme } label: {
                        Circle()
                            .fill(theme.color)
                            .frame(width: 30, height: 30)
                            .overlay {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(theme == .graphite ? Color(.systemBackground) : .white)
                                    .opacity(theme == selection ? 1 : 0)
                            }
                            .overlay {
                                Circle()
                                    .stroke(Color.primary, lineWidth: theme == selection ? 2 : 0)
                                    .padding(-3)
                            }
                            .padding(4) // keep the selection ring from clipping
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(theme.displayName)
                    .accessibilityAddTraits(theme == selection ? [.isButton, .isSelected] : .isButton)
                }
            }
            .padding(Space.sm)
        }
    }
}
