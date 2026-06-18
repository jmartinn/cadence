import SwiftUI

/// A labeled detail row: leading SF Symbol + secondary label, trailing emphasized value.
/// Used to build the subscription detail info card.
struct InfoRow: View {
    let systemImage: String
    let label: String
    let value: String
    /// Trailing disclosure chevron, shown when the row navigates somewhere (e.g. the
    /// "Part of" parent link). Defaults off so the static info rows stay chevron-free.
    var showsChevron: Bool = false

    var body: some View {
        HStack(spacing: Space.md) {
            Image(systemName: systemImage)
                .font(.system(size: 18))
                .foregroundStyle(.secondary)
                .frame(width: 24)
            Text(label)
                .foregroundStyle(.secondary)
            Spacer(minLength: Space.sm)
            Text(value)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.trailing)
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(.tertiaryLabel))
            }
        }
        .font(.system(size: 16))
        .padding(.horizontal, Space.lg)
        .padding(.vertical, Space.lg)
    }
}

#Preview {
    VStack(spacing: 0) {
        InfoRow(systemImage: "arrow.triangle.2.circlepath", label: "Billing cycle", value: "Monthly")
        Divider().padding(.leading, 16)
        InfoRow(systemImage: "creditcard", label: "Payment method", value: "Visa •••• 4821")
        Divider().padding(.leading, 16)
        InfoRow(systemImage: "square.stack.3d.up", label: "Part of", value: "Amazon Prime", showsChevron: true)
    }
    .background(Color(.secondarySystemGroupedBackground))
    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    .padding()
}
