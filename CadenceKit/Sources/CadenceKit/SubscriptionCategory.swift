import Foundation

/// A subscription's category, drawn from a fixed closed set.
///
/// `String`-backed + `Codable` + `CaseIterable` + `Sendable`, mirroring `BillingCycle` and
/// `SubscriptionStatus`. The raw values are the Title-Case **display** strings on purpose: the
/// SwiftData `@Model` stores `category` as a plain `String`, so matching raw values lets existing
/// rows round-trip without a migration. Unknown or blank stored strings coerce to `.other` at the
/// read boundary (`Subscription.categoryKind`). `.other` is declared last — it is both the default
/// for new subscriptions and the fallback bucket for unrecognized values.
public enum SubscriptionCategory: String, Codable, CaseIterable, Sendable {
    case entertainment = "Entertainment"
    case music = "Music"
    case news = "News"
    case productivity = "Productivity"
    case developerTools = "Developer Tools"
    case utilities = "Utilities"
    case shopping = "Shopping"
    case healthAndFitness = "Health & Fitness"
    case gaming = "Gaming"
    case education = "Education"
    case finance = "Finance"
    case social = "Social"
    case other = "Other"

    /// Human-facing label. A seam for future localization; today it is the raw value.
    public var displayName: String { rawValue }

    /// SF Symbol shown in the form picker and on the detail row. Tunable on-device.
    public var systemImage: String {
        switch self {
        case .entertainment: return "play.tv"
        case .music: return "music.note"
        case .news: return "newspaper"
        case .productivity: return "checklist"
        case .developerTools: return "chevron.left.forward.slash.chevron.right"
        case .utilities: return "wrench.and.screwdriver"
        case .shopping: return "cart"
        case .healthAndFitness: return "heart"
        case .gaming: return "gamecontroller"
        case .education: return "graduationcap"
        case .finance: return "creditcard"
        case .social: return "bubble.left.and.bubble.right"
        case .other: return "tag"
        }
    }
}
