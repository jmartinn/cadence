import SwiftUI

/// Circular service avatar. When the resolved brand has a bundled logo, draws that real app icon
/// clipped to a circle; otherwise the brand's first letter on its brand-color tile; otherwise a
/// deterministic hashed-hue tile + letter for unknown services. Shared by the list row (44pt),
/// detail header (72pt), calendar marker (18pt), and paid cluster (28pt). The render decision is
/// the pure `presentation(serviceKey:name:)`, unit-tested without drawing.
struct ServiceIcon: View {
    var serviceKey: String?
    let name: String
    var size: CGFloat = 44

    /// What to draw — resolved purely from the catalog, independent of rendering. The logo carries
    /// its own full-color artwork, so only the letter fallbacks need a tile/foreground.
    enum Presentation: Equatable {
        case logo(assetName: String)
        case letter(tile: Color, foreground: Color)
        case hashedLetter(tile: Color)
    }

    static func presentation(serviceKey: String?, name: String) -> Presentation {
        guard let brand = ServiceCatalog.brand(serviceKey: serviceKey, name: name) else {
            return .hashedLetter(tile: color(for: name))
        }
        if let asset = brand.iconAssetName {
            return .logo(assetName: asset)
        }
        return .letter(tile: brand.color, foreground: brand.color.contrastingForeground)
    }

    var body: some View {
        content
            .frame(width: size, height: size)
            .clipShape(Circle())
            .overlay(Circle().strokeBorder(Color(.separator), lineWidth: 0.5))
    }

    /// The fill for each branch — logo artwork, or a brand/hashed tile with its letter. `body`
    /// sizes, clips, and rings it with a hairline so even a white-background app icon (Notion,
    /// Google One) reads against a light UI.
    @ViewBuilder private var content: some View {
        switch Self.presentation(serviceKey: serviceKey, name: name) {
        case let .logo(assetName):
            Image(assetName).resizable().scaledToFill()
        case let .letter(tile, foreground):
            tile.overlay(letterLabel(foreground))
        case let .hashedLetter(tile):
            tile.overlay(letterLabel(.white))
        }
    }

    private func letterLabel(_ foreground: Color) -> some View {
        Text(Self.initial(for: name))
            .font(.system(size: size * 0.36, weight: .bold))
            .foregroundStyle(foreground)
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
        ServiceIcon(name: "Netflix")                                    // real logo
        ServiceIcon(serviceKey: "spotify", name: "Spotify", size: 72)   // real logo
        ServiceIcon(name: "iCloud+", size: 44)                          // known, no logo → letter
        ServiceIcon(name: "Unknown Service", size: 44)                  // hashed fallback
    }
    .padding()
}
