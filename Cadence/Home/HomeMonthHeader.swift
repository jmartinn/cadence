import SwiftUI

/// Top bar: centered month label flanked by nav chevrons, with a trailing profile button.
/// Forward-only navigation: the left chevron is disabled at the current-month floor.
/// Profile button is INERT this slice (Settings = deferred).
struct HomeMonthHeader: View {
    let month: Date
    var canGoBack: Bool
    var onPrevious: () -> Void
    var onNext: () -> Void

    private static let formatter: DateFormatter = {
        let f = DateFormatter(); f.setLocalizedDateFormatFromTemplate("MMMMyyyy"); return f
    }()

    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                Button(action: onPrevious) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(canGoBack ? .primary : Color(.tertiaryLabel))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .disabled(!canGoBack)

                Text(Self.formatter.string(from: month))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)

                Button(action: onNext) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
            }

            HStack {
                Spacer()
                Image(systemName: "person")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(Color(.secondarySystemFill)))
                    .accessibilityHidden(true)         // inert placeholder for the Settings slice
            }
        }
    }
}

#Preview {
    HomeMonthHeader(
        month: Date(timeIntervalSince1970: 1_764_547_200),
        canGoBack: true,
        onPrevious: {},
        onNext: {}
    ).padding()
}
