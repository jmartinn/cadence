import SwiftUI

/// "You will end the month with €X." with the amount in a sign-driven semantic color (green in
/// the black, red when over budget) — or a "Set your balance →" CTA when there is no anchor yet.
/// Tapping either opens the anchor sheet.
struct ForecastLineView: View {
    let projected: Decimal?
    let onEdit: () -> Void

    var body: some View {
        Button(action: onEdit) {
            if let projected {
                forecast(projected)
                    .font(.system(size: 17))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            } else {
                // Built explicitly (not `Label`) so the arrow reads as a trailing affordance
                // ("Set your balance →") rather than a leading icon.
                HStack(spacing: 6) {
                    Text("Set your balance")
                    Image(systemName: "arrow.right")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background(Color(.secondarySystemFill), in: Capsule())
            }
        }
        .buttonStyle(.plain)
    }

    private func forecast(_ amount: Decimal) -> Text {
        // `PriceText.split` floors the whole part toward −∞ and assumes non-negative input, so
        // format the magnitude and re-apply the sign here — otherwise e.g. -50,50 renders -51,50.
        let isNegative = amount < 0
        let formatted = (isNegative ? "-" : "") + PriceText.inlineString(isNegative ? -amount : amount)
        let lead = Text("You will end the month with ").foregroundColor(.secondary)
        let value = Text(formatted).foregroundColor(Self.balanceColor(amount)).fontWeight(.semibold)
        let dot = Text(".").foregroundColor(.secondary)
        return Text("\(lead)\(value)\(dot)")
    }

    /// Sign-driven semantic color for the projected balance: green when the month ends in the
    /// black, red when it ends negative (over budget). A negative end-of-month balance is the
    /// whole point of the forecaster, so it must never read as the "good" positive color.
    private static func balanceColor(_ amount: Decimal) -> Color {
        amount < 0 ? .red : .green
    }
}

#Preview {
    VStack(spacing: 24) {
        ForecastLineView(projected: Decimal(string: "1025.06")!) {}
        ForecastLineView(projected: Decimal(string: "-50.50")!) {}
        ForecastLineView(projected: nil) {}
    }.padding()
}
