import SwiftUI

/// One known service's brand identity. `hex` is the monogram-fallback tile color;
/// `iconAssetName` names a bundled App Store app icon (== `slug` when present, `nil` when no icon
/// is bundled → monogram fallback). `color` parses `hex` lazily so a typo surfaces in
/// `Color(hex:)` rather than at a force-unwrap.
struct ServiceBrand: Equatable {
    let slug: String // canonical key, e.g. "netflix"
    let displayName: String // e.g. "Netflix"
    let hex: String // "#RRGGBB" — monogram-fallback tile color
    let iconAssetName: String? // bundled app-icon asset name (== slug), nil = no logo → monogram
    let aliases: [String] // extra normalized forms that resolve here, e.g. ["disney"]

    var color: Color { Color(hex: hex) ?? .gray }
}

/// Pure presentation-layer lookup: a flat brand table plus an O(1) resolver. No persistence or
/// domain involvement. Resolution order: explicit serviceKey → normalized name slug → alias →
/// longest-prefix fallback → nil.
enum ServiceCatalog {
    /// The brand table — 50+ entries covering streaming, music, productivity, AI, news,
    /// fitness, and gaming. The resolver and tests are size-agnostic.
    static let all: [ServiceBrand] = [
        // Seed
        ServiceBrand(slug: "netflix", displayName: "Netflix", hex: "#E50914", iconAssetName: "netflix", aliases: []),
        ServiceBrand(slug: "disney-plus", displayName: "Disney+", hex: "#113CCF", iconAssetName: "disney-plus", aliases: ["disney"]),
        ServiceBrand(slug: "nyt", displayName: "NYT", hex: "#000000", iconAssetName: "nyt", aliases: ["newyorktimes", "thenewyorktimes"]),
        ServiceBrand(slug: "figma", displayName: "Figma", hex: "#F24E1E", iconAssetName: "figma", aliases: []),
        ServiceBrand(slug: "spotify", displayName: "Spotify", hex: "#1DB954", iconAssetName: "spotify", aliases: []),
        ServiceBrand(slug: "icloud", displayName: "iCloud+", hex: "#3693F3", iconAssetName: "icloud", aliases: ["icloudplus"]),
        ServiceBrand(slug: "notion", displayName: "Notion", hex: "#000000", iconAssetName: "notion", aliases: []),
        ServiceBrand(slug: "youtube", displayName: "YouTube Premium", hex: "#FF0000", iconAssetName: "youtube", aliases: ["youtubepremium"]),
        ServiceBrand(slug: "amazon-prime", displayName: "Amazon Prime", hex: "#00A8E1", iconAssetName: "amazon-prime", aliases: ["amazonprimevideo", "primevideo"]),

        // Streaming
        ServiceBrand(slug: "hbo-max", displayName: "HBO Max", hex: "#002BE7", iconAssetName: "hbo-max", aliases: ["max", "hbo"]),
        ServiceBrand(slug: "hulu", displayName: "Hulu", hex: "#1CE783", iconAssetName: "hulu", aliases: []),
        ServiceBrand(slug: "apple-tv-plus", displayName: "Apple TV+", hex: "#000000", iconAssetName: "apple-tv-plus", aliases: ["appletv", "atv"]),
        ServiceBrand(slug: "paramount-plus", displayName: "Paramount+", hex: "#0064FF", iconAssetName: "paramount-plus", aliases: ["paramount"]),
        ServiceBrand(slug: "peacock", displayName: "Peacock", hex: "#F9B500", iconAssetName: "peacock", aliases: ["peacocktv", "nbcpeacock"]),
        ServiceBrand(slug: "twitch", displayName: "Twitch", hex: "#9146FF", iconAssetName: "twitch", aliases: []),
        ServiceBrand(slug: "crunchyroll", displayName: "Crunchyroll", hex: "#F47521", iconAssetName: "crunchyroll", aliases: ["cr"]),

        // Music / Audio
        ServiceBrand(slug: "apple-music", displayName: "Apple Music", hex: "#FC3C44", iconAssetName: "apple-music", aliases: []),
        ServiceBrand(slug: "youtube-music", displayName: "YouTube Music", hex: "#FF0000", iconAssetName: "youtube-music", aliases: ["ytmusic"]),
        ServiceBrand(slug: "tidal", displayName: "Tidal", hex: "#000000", iconAssetName: "tidal", aliases: []),
        ServiceBrand(slug: "deezer", displayName: "Deezer", hex: "#EF5466", iconAssetName: "deezer", aliases: []),
        ServiceBrand(slug: "soundcloud", displayName: "SoundCloud", hex: "#FF5500", iconAssetName: "soundcloud", aliases: []),
        ServiceBrand(slug: "audible", displayName: "Audible", hex: "#F8991D", iconAssetName: "audible", aliases: []),

        // Productivity & Cloud
        ServiceBrand(slug: "google-one", displayName: "Google One", hex: "#4285F4", iconAssetName: "google-one", aliases: ["google1", "googleonestorage"]),
        ServiceBrand(slug: "dropbox", displayName: "Dropbox", hex: "#0061FF", iconAssetName: "dropbox", aliases: ["dbx"]),
        ServiceBrand(slug: "microsoft-365", displayName: "Microsoft 365", hex: "#0078D4", iconAssetName: "microsoft-365", aliases: ["ms365", "office365", "microsoftoffice", "m365"]),
        ServiceBrand(slug: "adobe-creative-cloud", displayName: "Adobe Creative Cloud", hex: "#FF0000", iconAssetName: "adobe-creative-cloud", aliases: ["adobe", "creativecloud", "adobecc", "cc"]),
        ServiceBrand(slug: "1password", displayName: "1Password", hex: "#1A6DFF", iconAssetName: "1password", aliases: ["onepassword", "1pass"]),
        ServiceBrand(slug: "slack", displayName: "Slack", hex: "#4A154B", iconAssetName: "slack", aliases: []),
        ServiceBrand(slug: "linear", displayName: "Linear", hex: "#5E6AD2", iconAssetName: "linear", aliases: []),
        ServiceBrand(slug: "github", displayName: "GitHub", hex: "#181717", iconAssetName: "github", aliases: ["gh"]),
        ServiceBrand(slug: "todoist", displayName: "Todoist", hex: "#DB4035", iconAssetName: "todoist", aliases: []),
        ServiceBrand(slug: "evernote", displayName: "Evernote", hex: "#00A82D", iconAssetName: "evernote", aliases: []),

        // AI
        ServiceBrand(slug: "chatgpt", displayName: "ChatGPT", hex: "#10A37F", iconAssetName: "chatgpt", aliases: ["openai", "gpt", "gpt4", "openaichatgpt"]),
        ServiceBrand(slug: "claude", displayName: "Claude", hex: "#D97757", iconAssetName: "claude", aliases: ["anthropic", "claudeai"]),
        ServiceBrand(slug: "perplexity", displayName: "Perplexity", hex: "#20B2AA", iconAssetName: "perplexity", aliases: ["perplexityai"]),
        ServiceBrand(slug: "midjourney", displayName: "Midjourney", hex: "#000000", iconAssetName: "midjourney", aliases: ["mj"]),
        ServiceBrand(slug: "github-copilot", displayName: "GitHub Copilot", hex: "#24292E", iconAssetName: "github-copilot", aliases: ["copilot", "ghcopilot"]),
        ServiceBrand(slug: "grok", displayName: "Grok", hex: "#000000", iconAssetName: "grok", aliases: ["xai", "grokai"]),
        ServiceBrand(slug: "cursor", displayName: "Cursor", hex: "#000000", iconAssetName: "cursor", aliases: ["cursorai", "anysphere"]),

        // News & Reading
        ServiceBrand(slug: "the-economist", displayName: "The Economist", hex: "#E3120B", iconAssetName: "the-economist", aliases: ["economist"]),
        ServiceBrand(slug: "medium", displayName: "Medium", hex: "#02B875", iconAssetName: "medium", aliases: []),
        ServiceBrand(slug: "substack", displayName: "Substack", hex: "#FF6719", iconAssetName: "substack", aliases: []),
        ServiceBrand(slug: "kindle-unlimited", displayName: "Kindle Unlimited", hex: "#FF9900", iconAssetName: "kindle-unlimited", aliases: ["kindle", "ku"]),

        // Fitness & Lifestyle
        ServiceBrand(slug: "strava", displayName: "Strava", hex: "#FC4C02", iconAssetName: "strava", aliases: []),
        ServiceBrand(slug: "peloton", displayName: "Peloton", hex: "#D9232E", iconAssetName: "peloton", aliases: []),
        ServiceBrand(slug: "headspace", displayName: "Headspace", hex: "#F47D31", iconAssetName: "headspace", aliases: []),
        ServiceBrand(slug: "calm", displayName: "Calm", hex: "#4A90D9", iconAssetName: "calm", aliases: []),
        ServiceBrand(slug: "duolingo", displayName: "Duolingo", hex: "#58CC02", iconAssetName: "duolingo", aliases: []),

        // Gaming
        ServiceBrand(slug: "playstation-plus", displayName: "PlayStation Plus", hex: "#003791", iconAssetName: "playstation-plus", aliases: ["psplus", "psnplus", "playstation"]),
        ServiceBrand(slug: "xbox-game-pass", displayName: "Xbox Game Pass", hex: "#107C10", iconAssetName: "xbox-game-pass", aliases: ["gamepass", "xgp", "xbox"]),
        ServiceBrand(slug: "nintendo-switch-online", displayName: "Nintendo Switch Online", hex: "#E60012", iconAssetName: "nintendo-switch-online", aliases: ["nso", "switchonline", "nintendo"]),

        // Social & Community
        ServiceBrand(slug: "discord", displayName: "Discord", hex: "#5865F2", iconAssetName: "discord", aliases: []),

        // Social & Community (catalog-widening)
        ServiceBrand(slug: "telegram", displayName: "Telegram", hex: "#26A5E4", iconAssetName: "telegram", aliases: ["telegrampremium"]),
        ServiceBrand(slug: "x", displayName: "X", hex: "#000000", iconAssetName: "x", aliases: ["twitter", "xpremium", "twitterblue"]),
        ServiceBrand(slug: "reddit", displayName: "Reddit", hex: "#FF4500", iconAssetName: "reddit", aliases: ["redditpremium"]),
        ServiceBrand(slug: "linkedin", displayName: "LinkedIn", hex: "#0A66C2", iconAssetName: "linkedin", aliases: ["linkedinpremium"]),
        ServiceBrand(slug: "patreon", displayName: "Patreon", hex: "#FF424D", iconAssetName: "patreon", aliases: []),
        ServiceBrand(slug: "snapchat", displayName: "Snapchat", hex: "#FFFC00", iconAssetName: "snapchat", aliases: ["snapchatplus", "snap"]),

        // Developer Tools
        ServiceBrand(slug: "vercel", displayName: "Vercel", hex: "#000000", iconAssetName: "vercel", aliases: []),
        ServiceBrand(slug: "supabase", displayName: "Supabase", hex: "#3FCF8E", iconAssetName: "supabase", aliases: []),
        ServiceBrand(slug: "raycast", displayName: "Raycast", hex: "#FF6363", iconAssetName: "raycast", aliases: ["raycastpro"]),
        ServiceBrand(slug: "obsidian", displayName: "Obsidian", hex: "#7C3AED", iconAssetName: "obsidian", aliases: ["obsidianmd", "obsidiansync"]),
        ServiceBrand(slug: "nextdns", displayName: "NextDNS", hex: "#3D7BF7", iconAssetName: "nextdns", aliases: []),

        // AI (catalog-widening)
        ServiceBrand(slug: "elevenlabs", displayName: "ElevenLabs", hex: "#000000", iconAssetName: "elevenlabs", aliases: ["11labs"]),
        ServiceBrand(slug: "gemini", displayName: "Gemini", hex: "#1C69FF", iconAssetName: "gemini", aliases: ["googlegemini", "geminiadvanced", "bard"]),
        ServiceBrand(slug: "v0", displayName: "v0", hex: "#000000", iconAssetName: "v0", aliases: ["v0dev", "vercelv0"]),

        // Apple Services & ecosystem
        ServiceBrand(slug: "apple-arcade", displayName: "Apple Arcade", hex: "#000000", iconAssetName: "apple-arcade", aliases: ["arcade"]),
        ServiceBrand(slug: "apple-one", displayName: "Apple One", hex: "#000000", iconAssetName: nil, aliases: []),
        ServiceBrand(slug: "apple-news", displayName: "Apple News+", hex: "#FA2D48", iconAssetName: "apple-news", aliases: ["applenewsplus"]),
        ServiceBrand(slug: "apple-fitness", displayName: "Apple Fitness+", hex: "#30D158", iconAssetName: "apple-fitness", aliases: ["fitnessplus"]),

        // Streaming — Prime Video channels (logo mop-up)
        ServiceBrand(slug: "mgm-plus", displayName: "MGM+", hex: "#0B0B0B", iconAssetName: "mgm-plus", aliases: ["mgm", "epix"]),
        ServiceBrand(slug: "starz", displayName: "STARZ", hex: "#000000", iconAssetName: "starz", aliases: ["starzplay"]),
        ServiceBrand(slug: "amc-plus", displayName: "AMC+", hex: "#0A0A0A", iconAssetName: "amc-plus", aliases: ["amc"]),
        ServiceBrand(slug: "lionsgate", displayName: "Lionsgate", hex: "#0B0B0B", iconAssetName: "lionsgate", aliases: ["lionsgateplay", "lionsgateplus", "lgplay"]),

        // Streaming — Spain & Europe (logo mop-up)
        ServiceBrand(slug: "skyshowtime", displayName: "SkyShowtime", hex: "#0E0E2C", iconAssetName: "skyshowtime", aliases: []),
        ServiceBrand(slug: "movistar-plus", displayName: "Movistar Plus+", hex: "#019DF4", iconAssetName: "movistar-plus", aliases: ["movistar", "yomvi"]),
        ServiceBrand(slug: "dazn", displayName: "DAZN", hex: "#0F0F0F", iconAssetName: "dazn", aliases: []),
        ServiceBrand(slug: "filmin", displayName: "Filmin", hex: "#E8482B", iconAssetName: "filmin", aliases: []),
        ServiceBrand(slug: "flixole", displayName: "FlixOlé", hex: "#D81E27", iconAssetName: "flixole", aliases: ["flixolé"]),
        ServiceBrand(slug: "atresplayer", displayName: "atresplayer", hex: "#FF6C0E", iconAssetName: "atresplayer", aliases: ["a3player", "antena3", "atresmedia"]),
        ServiceBrand(slug: "mitele", displayName: "Mitele", hex: "#0A47A9", iconAssetName: "mitele", aliases: ["miteleplus", "mediaset", "mediasetinfinity"]),
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

    /// Resolve a subscription to its brand: explicit `serviceKey` first, then the display name,
    /// then a longest-prefix fallback so an extended label still resolves (e.g. "Claude Code" →
    /// claude, "Spotify Premium" → spotify).
    static func brand(serviceKey: String?, name: String) -> ServiceBrand? {
        if let key = serviceKey, let hit = index[normalize(key)] { return hit }
        let normalizedName = normalize(name)
        if let hit = index[normalizedName] { return hit }
        return prefixMatch(normalizedName)
    }

    /// Fallback for inputs that extend a known key. Requires the matched key to be ≥4 characters,
    /// so short aliases ("gh", "cc") can't swallow unrelated names (e.g. "Ghost" must not hit
    /// github's "gh"), and picks the longest matching key to prefer the most specific brand.
    private static func prefixMatch(_ normalized: String) -> ServiceBrand? {
        guard normalized.count >= 4 else { return nil }
        var best: (key: String, brand: ServiceBrand)?
        for (key, brand) in index where key.count >= 4 && normalized.hasPrefix(key) {
            if best == nil || key.count > best!.key.count { best = (key, brand) }
        }
        return best?.brand
    }
}
