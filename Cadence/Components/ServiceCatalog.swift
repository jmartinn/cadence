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
    /// The brand table — 50+ entries covering streaming, music, productivity, AI, news,
    /// fitness, and gaming. The resolver and tests are size-agnostic.
    static let all: [ServiceBrand] = [
        // Seed
        ServiceBrand(slug: "netflix", displayName: "Netflix", hex: "#E50914", aliases: []),
        ServiceBrand(slug: "disney-plus", displayName: "Disney+", hex: "#113CCF", aliases: ["disney"]),
        ServiceBrand(slug: "nyt", displayName: "NYT", hex: "#000000", aliases: ["newyorktimes", "thenewyorktimes"]),
        ServiceBrand(slug: "figma", displayName: "Figma", hex: "#F24E1E", aliases: []),
        ServiceBrand(slug: "spotify", displayName: "Spotify", hex: "#1DB954", aliases: []),
        ServiceBrand(slug: "icloud", displayName: "iCloud+", hex: "#3693F3", aliases: ["icloudplus"]),
        ServiceBrand(slug: "notion", displayName: "Notion", hex: "#000000", aliases: []),
        ServiceBrand(slug: "youtube", displayName: "YouTube Premium", hex: "#FF0000", aliases: ["youtubepremium"]),
        ServiceBrand(slug: "amazon-prime", displayName: "Amazon Prime", hex: "#00A8E1", aliases: ["amazonprimevideo", "primevideo"]),

        // Streaming
        ServiceBrand(slug: "hbo-max", displayName: "Max", hex: "#002BE7", aliases: ["max", "hbo"]),
        ServiceBrand(slug: "hulu", displayName: "Hulu", hex: "#1CE783", aliases: []),
        ServiceBrand(slug: "apple-tv-plus", displayName: "Apple TV+", hex: "#000000", aliases: ["appletv", "atv"]),
        ServiceBrand(slug: "paramount-plus", displayName: "Paramount+", hex: "#0064FF", aliases: ["paramount"]),
        ServiceBrand(slug: "peacock", displayName: "Peacock", hex: "#F9B500", aliases: ["peacocktv", "nbcpeacock"]),
        ServiceBrand(slug: "twitch", displayName: "Twitch", hex: "#9146FF", aliases: []),
        ServiceBrand(slug: "crunchyroll", displayName: "Crunchyroll", hex: "#F47521", aliases: ["cr"]),

        // Music / Audio
        ServiceBrand(slug: "apple-music", displayName: "Apple Music", hex: "#FC3C44", aliases: []),
        ServiceBrand(slug: "youtube-music", displayName: "YouTube Music", hex: "#FF0000", aliases: ["ytmusic"]),
        ServiceBrand(slug: "tidal", displayName: "Tidal", hex: "#000000", aliases: []),
        ServiceBrand(slug: "deezer", displayName: "Deezer", hex: "#EF5466", aliases: []),
        ServiceBrand(slug: "soundcloud", displayName: "SoundCloud", hex: "#FF5500", aliases: []),
        ServiceBrand(slug: "audible", displayName: "Audible", hex: "#F8991D", aliases: []),

        // Productivity & Cloud
        ServiceBrand(slug: "google-one", displayName: "Google One", hex: "#4285F4", aliases: ["google1", "googleonestorage"]),
        ServiceBrand(slug: "dropbox", displayName: "Dropbox", hex: "#0061FF", aliases: ["dbx"]),
        ServiceBrand(slug: "microsoft-365", displayName: "Microsoft 365", hex: "#0078D4", aliases: ["ms365", "office365", "microsoftoffice", "m365"]),
        ServiceBrand(slug: "adobe-creative-cloud", displayName: "Adobe Creative Cloud", hex: "#FF0000", aliases: ["adobe", "creativecloud", "adobecc", "cc"]),
        ServiceBrand(slug: "1password", displayName: "1Password", hex: "#1A6DFF", aliases: ["onepassword", "1pass"]),
        ServiceBrand(slug: "slack", displayName: "Slack", hex: "#4A154B", aliases: []),
        ServiceBrand(slug: "linear", displayName: "Linear", hex: "#5E6AD2", aliases: []),
        ServiceBrand(slug: "github", displayName: "GitHub", hex: "#181717", aliases: ["gh"]),
        ServiceBrand(slug: "todoist", displayName: "Todoist", hex: "#DB4035", aliases: []),
        ServiceBrand(slug: "evernote", displayName: "Evernote", hex: "#00A82D", aliases: []),

        // AI
        ServiceBrand(slug: "chatgpt", displayName: "ChatGPT", hex: "#10A37F", aliases: ["openai", "gpt", "gpt4", "openaichatgpt"]),
        ServiceBrand(slug: "claude", displayName: "Claude", hex: "#D97757", aliases: ["anthropic", "claudeai"]),
        ServiceBrand(slug: "perplexity", displayName: "Perplexity", hex: "#20B2AA", aliases: ["perplexityai"]),
        ServiceBrand(slug: "midjourney", displayName: "Midjourney", hex: "#000000", aliases: ["mj"]),
        ServiceBrand(slug: "github-copilot", displayName: "GitHub Copilot", hex: "#24292E", aliases: ["copilot", "ghcopilot"]),

        // News & Reading
        ServiceBrand(slug: "the-economist", displayName: "The Economist", hex: "#E3120B", aliases: ["economist"]),
        ServiceBrand(slug: "medium", displayName: "Medium", hex: "#02B875", aliases: []),
        ServiceBrand(slug: "substack", displayName: "Substack", hex: "#FF6719", aliases: []),
        ServiceBrand(slug: "kindle-unlimited", displayName: "Kindle Unlimited", hex: "#FF9900", aliases: ["kindle", "ku"]),

        // Fitness & Lifestyle
        ServiceBrand(slug: "strava", displayName: "Strava", hex: "#FC4C02", aliases: []),
        ServiceBrand(slug: "peloton", displayName: "Peloton", hex: "#D9232E", aliases: []),
        ServiceBrand(slug: "headspace", displayName: "Headspace", hex: "#F47D31", aliases: []),
        ServiceBrand(slug: "calm", displayName: "Calm", hex: "#4A90D9", aliases: []),
        ServiceBrand(slug: "duolingo", displayName: "Duolingo", hex: "#58CC02", aliases: []),

        // Gaming
        ServiceBrand(slug: "playstation-plus", displayName: "PlayStation Plus", hex: "#003791", aliases: ["psplus", "psnplus", "playstation"]),
        ServiceBrand(slug: "xbox-game-pass", displayName: "Xbox Game Pass", hex: "#107C10", aliases: ["gamepass", "xgp", "xbox"]),
        ServiceBrand(slug: "nintendo-switch-online", displayName: "Nintendo Switch Online", hex: "#E60012", aliases: ["nso", "switchonline", "nintendo"]),

        // Social & Community
        ServiceBrand(slug: "discord", displayName: "Discord", hex: "#5865F2", aliases: []),
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
            for alias in brand.aliases {
                map[normalize(alias)] = brand
            }
        }
        return map
    }()

    /// Resolve a subscription to its brand: explicit `serviceKey` first, then the display name.
    static func brand(serviceKey: String?, name: String) -> ServiceBrand? {
        if let key = serviceKey, let hit = index[normalize(key)] { return hit }
        return index[normalize(name)]
    }
}
