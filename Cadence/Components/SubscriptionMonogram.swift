import SwiftUI

/// Circular monogram for a service: the name's first letter on a deterministic hashed hue.
/// Shared by the list row (44pt) and the detail header (72pt). The hue hash is a non-money
/// `Double`, which is fine — only currency must stay `Decimal`.
struct SubscriptionMonogram: View {
    let name: String
    var size: CGFloat = 44

    var body: some View {
        Circle()
            .fill(Self.color(for: name))
            .frame(width: size, height: size)
            .overlay(
                Text(Self.initial(for: name))
                    .font(.system(size: size * 0.36, weight: .bold))
                    .foregroundColor(.white)
            )
    }

    static func initial(for name: String) -> String {
        guard let first = name.first else { return "?" }
        return String(first).uppercased()
    }

    static func color(for name: String) -> Color {
        let hash = name.unicodeScalars.reduce(0) { $0 &+ Int($1.value) }
        let hue = Double(hash % 360) / 360.0
        return Color(hue: hue, saturation: 0.55, brightness: 0.75)
    }
}

#Preview {
    HStack(spacing: 16) {
        SubscriptionMonogram(name: "Netflix")
        SubscriptionMonogram(name: "Spotify", size: 72)
    }
    .padding()
}
