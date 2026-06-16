import SwiftUI

/// One known service's brand identity. `hex` is a hand-picked brand color (the stand-in for a
/// future logo asset, see spec §8); `color` parses it lazily so the table stays readable and a
/// typo surfaces in `Color(hex:)` rather than at a force-unwrap.
struct ServiceBrand: Equatable {
    let slug: String // canonical key, e.g. "netflix"
    let displayName: String // e.g. "Netflix"
    let hex: String // "#RRGGBB"
    let aliases: [String] // extra normalized forms that resolve here, e.g. ["disney"]

    var color: Color { Color(hex: hex) ?? .gray }
}

/// Pure presentation-layer lookup: a flat brand table plus an O(1) resolver. No persistence or
/// domain involvement. Resolution order: explicit serviceKey → normalized name slug → alias → nil.
enum ServiceCatalog {
    /// The brand table. Task 4 expands this to 50+ entries; the resolver and tests are size-agnostic.
    static let all: [ServiceBrand] = [
        ServiceBrand(slug: "netflix", displayName: "Netflix", hex: "#E50914", aliases: []),
        ServiceBrand(slug: "disney-plus", displayName: "Disney+", hex: "#113CCF", aliases: ["disney"]),
        ServiceBrand(slug: "nyt", displayName: "NYT", hex: "#000000", aliases: ["newyorktimes", "thenewyorktimes"]),
        ServiceBrand(slug: "figma", displayName: "Figma", hex: "#F24E1E", aliases: []),
        ServiceBrand(slug: "spotify", displayName: "Spotify", hex: "#1DB954", aliases: []),
        ServiceBrand(slug: "icloud", displayName: "iCloud+", hex: "#3693F3", aliases: ["icloudplus"]),
        ServiceBrand(slug: "notion", displayName: "Notion", hex: "#000000", aliases: []),
        ServiceBrand(slug: "youtube", displayName: "YouTube Premium", hex: "#FF0000", aliases: ["youtubepremium"]),
        ServiceBrand(slug: "amazon-prime", displayName: "Amazon Prime", hex: "#00A8E1", aliases: ["amazonprimevideo", "primevideo"]),
    ]

    /// Lowercase and strip every non-alphanumeric character. "Disney+" → "disney",
    /// "amazon-prime" → "amazonprime". Aliases bridge multi-word gaps the slug cannot.
    static func normalize(_ raw: String) -> String {
        raw.lowercased().unicodeScalars
            .filter { CharacterSet.alphanumerics.contains($0) }
            .map(Character.init)
            .reduce(into: "") { $0.append($1) }
    }

    /// Index every brand under its normalized slug and each normalized alias, for O(1) lookup.
    private static let index: [String: ServiceBrand] = {
        var map: [String: ServiceBrand] = [:]
        for brand in all {
            map[normalize(brand.slug)] = brand
            for alias in brand.aliases { map[normalize(alias)] = brand }
        }
        return map
    }()

    /// Resolve a subscription to its brand: explicit `serviceKey` first, then the display name.
    static func brand(serviceKey: String?, name: String) -> ServiceBrand? {
        if let key = serviceKey, let hit = index[normalize(key)] { return hit }
        return index[normalize(name)]
    }
}
