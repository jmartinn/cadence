import SwiftUI

/// A labeled detail row: leading SF Symbol + secondary label, trailing emphasized value.
/// Used to build the subscription detail info card.
struct InfoRow: View {
    let systemImage: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 18))
                .foregroundStyle(.secondary)
                .frame(width: 24)
            Text(label)
                .foregroundStyle(.secondary)
            Spacer(minLength: 8)
            Text(value)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.trailing)
        }
        .font(.system(size: 16))
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

#Preview {
    VStack(spacing: 0) {
        InfoRow(systemImage: "arrow.triangle.2.circlepath", label: "Billing cycle", value: "Monthly")
        Divider().padding(.leading, 16)
        InfoRow(systemImage: "creditcard", label: "Payment method", value: "Visa •••• 4821")
    }
    .background(Color(.secondarySystemGroupedBackground))
    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    .padding()
}
