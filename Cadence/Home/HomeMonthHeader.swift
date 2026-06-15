import SwiftUI

/// Top bar: centered month label flanked by chevrons, with a trailing profile button.
/// Chevrons and profile are INERT this slice (month nav = deferred; Settings = deferred).
struct HomeMonthHeader: View {
    let month: Date

    private static let formatter: DateFormatter = {
        let f = DateFormatter(); f.setLocalizedDateFormatFromTemplate("MMMMyyyy"); return f
    }()

    var body: some View {
        ZStack {
            HStack(spacing: Space.lg) {
                Image(systemName: "chevron.left")
                Text(Self.formatter.string(from: month))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                Image(systemName: "chevron.right")
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(Color(.tertiaryLabel))   // dimmed: nav not active yet

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
    HomeMonthHeader(month: Date(timeIntervalSince1970: 1_764_547_200)).padding()
}
