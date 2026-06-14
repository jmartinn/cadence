import SwiftUI

/// "You will end the month with €X." with the amount in the positive color — or a
/// "Set your balance" CTA when there is no anchor yet. Tapping either opens the anchor sheet.
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
                Label("Set your balance", systemImage: "arrow.right")
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
        let lead = Text("You will end the month with ").foregroundColor(.secondary)
        let value = Text(Self.amountString(amount)).foregroundColor(.green).fontWeight(.semibold)
        let dot = Text(".").foregroundColor(.secondary)
        return Text("\(lead)\(value)\(dot)")
    }

    private static func amountString(_ d: Decimal) -> String {
        let parts = PriceText.split(d)
        let sep = Locale.current.decimalSeparator ?? ","
        return "\(parts.whole)\(sep)\(parts.cents)€"
    }
}

#Preview {
    VStack(spacing: 24) {
        ForecastLineView(projected: Decimal(string: "1025.06")!) {}
        ForecastLineView(projected: nil) {}
    }.padding()
}
