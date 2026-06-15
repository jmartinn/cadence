import SwiftUI

/// "Total spending" caption over the monthly run-rate hero. Reuses `PriceText`.
struct SpendingHeadline: View {
    let monthlyTotal: Decimal

    var body: some View {
        VStack(spacing: Space.xs) {
            Text("Total spending")
                .font(.system(size: 15))
                .foregroundColor(.secondary)
            PriceText(monthlyTotal, symbolPosition: .leading, suffix: "/m",
                      wholeSize: 64, symbolSize: 34, centsSize: 28)
        }
    }
}

#Preview {
    SpendingHeadline(monthlyTotal: Decimal(string: "90.94")!).padding()
}
