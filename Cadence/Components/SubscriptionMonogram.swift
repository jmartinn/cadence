import SwiftUI

/// Circular service avatar: brand color tile + the name's first letter when the service is known
/// to `ServiceCatalog`, otherwise a deterministic hashed-hue tile. Shared by the list row (44pt),
/// the detail header (72pt), the calendar marker (18pt), and the paid cluster (28pt). The hue hash
/// is a non-money `Double`, which is fine — only currency must stay `Decimal`.
struct SubscriptionMonogram: View {
    var serviceKey: String?
    let name: String
    var size: CGFloat = 44

    var body: some View {
        let brandColor = ServiceCatalog.brand(serviceKey: serviceKey, name: name)?.color
        let tile = brandColor ?? Self.color(for: name)
        let letter = brandColor?.contrastingForeground ?? .white
        Circle()
            .fill(tile)
            .frame(width: size, height: size)
            .overlay(
                Text(Self.initial(for: name))
                    .font(.system(size: size * 0.36, weight: .bold))
                    .foregroundColor(letter)
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
        SubscriptionMonogram(name: "Netflix")                                     // brand red
        SubscriptionMonogram(serviceKey: "spotify", name: "Spotify", size: 72)   // brand green
        SubscriptionMonogram(name: "Unknown Service", size: 44)                   // hashed fallback
    }
    .padding()
}
