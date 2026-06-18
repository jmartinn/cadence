@testable import Cadence
import SwiftUI
import Testing

struct ServiceCatalogTests {
    @Test func normalizeStripsCaseAndPunctuation() {
        #expect(ServiceCatalog.normalize("Disney+") == "disney")
        #expect(ServiceCatalog.normalize("amazon-prime") == "amazonprime")
        #expect(ServiceCatalog.normalize("YouTube Premium") == "youtubepremium")
        #expect(ServiceCatalog.normalize("  NYT ") == "nyt")
    }

    @Test func resolvesByExplicitServiceKey() {
        let brand = ServiceCatalog.brand(serviceKey: "netflix", name: "Whatever Label")
        #expect(brand?.slug == "netflix")
    }

    @Test func resolvesByNameSlugWhenKeyIsNil() {
        let brand = ServiceCatalog.brand(serviceKey: nil, name: "Spotify")
        #expect(brand?.slug == "spotify")
    }

    @Test func resolvesByAlias() {
        // "Disney+" normalizes to "disney", reachable only via the alias on the disney-plus entry.
        let brand = ServiceCatalog.brand(serviceKey: nil, name: "Disney+")
        #expect(brand?.slug == "disney-plus")
    }

    @Test func keyAndEquivalentNameResolveToSameBrand() {
        let byKey = ServiceCatalog.brand(serviceKey: "amazon-prime", name: "")
        let byName = ServiceCatalog.brand(serviceKey: nil, name: "Amazon Prime")
        #expect(byKey == byName)
        #expect(byKey != nil)
    }

    @Test func unknownServiceReturnsNil() {
        #expect(ServiceCatalog.brand(serviceKey: nil, name: "Totally Unknown Co") == nil)
        #expect(ServiceCatalog.brand(serviceKey: "no-such-key", name: "") == nil)
    }

    @Test func allSampleServiceKeysResolve() {
        let sampleKeys = ["netflix", "disney-plus", "nyt", "figma",
                          "spotify", "icloud", "notion", "youtube", "amazon-prime"]
        for key in sampleKeys {
            #expect(ServiceCatalog.brand(serviceKey: key, name: "") != nil, "\(key) must resolve")
        }
    }

    @Test func catalogWideningBrandsResolveByKeyAndAlias() {
        // The 17 brands added in the catalog-widening slice all resolve by explicit serviceKey.
        let slugs = ["telegram", "x", "reddit", "linkedin", "patreon", "snapchat",
                     "vercel", "supabase", "raycast", "obsidian", "nextdns",
                     "elevenlabs", "gemini", "v0",
                     "apple-arcade", "apple-one", "apple-news", "apple-fitness"]
        for slug in slugs {
            #expect(ServiceCatalog.brand(serviceKey: slug, name: "") != nil, "\(slug) must resolve")
        }
        // A representative alias / display name from each sourcing group resolves to the right brand.
        #expect(ServiceCatalog.brand(serviceKey: nil, name: "Twitter")?.slug == "x")
        #expect(ServiceCatalog.brand(serviceKey: nil, name: "Snapchat+")?.slug == "snapchat")
        #expect(ServiceCatalog.brand(serviceKey: nil, name: "Bard")?.slug == "gemini")
        #expect(ServiceCatalog.brand(serviceKey: nil, name: "Apple News")?.slug == "apple-news")
    }

    @Test func everySlugIsUnique() {
        let slugs = ServiceCatalog.all.map(\.slug)
        #expect(Set(slugs).count == slugs.count, "duplicate slug in catalog")
    }

    @Test func noNormalizedKeyCollisions() {
        // Every slug + alias, normalized, must be globally unique — otherwise one entry
        // silently shadows another in the lookup index.
        var keys: [String] = []
        for brand in ServiceCatalog.all {
            keys.append(ServiceCatalog.normalize(brand.slug))
            keys.append(contentsOf: brand.aliases.map { ServiceCatalog.normalize($0) })
        }
        #expect(Set(keys).count == keys.count, "alias/slug collision in catalog")
    }

    @Test func everyHexParses() {
        for brand in ServiceCatalog.all {
            #expect(Color(hex: brand.hex) != nil, "bad hex for \(brand.slug): \(brand.hex)")
        }
    }

    @Test func everyDisplayNameIsNonEmpty() {
        for brand in ServiceCatalog.all {
            #expect(!brand.displayName.isEmpty, "empty displayName for \(brand.slug)")
        }
    }

    @Test func catalogIsBroad() {
        #expect(ServiceCatalog.all.count >= 50, "spec §11.3 requires a broad (50+) catalog")
    }

    @Test func everyNonNilIconAssetNameEqualsSlug() {
        for brand in ServiceCatalog.all where brand.iconAssetName != nil {
            #expect(brand.iconAssetName == brand.slug, "\(brand.slug): iconAssetName should equal slug")
        }
    }

    @Test func uncoveredBrandsHaveNilIconAssetName() {
        // Two catalog brands have no bundled logo and stay brand-color letter tiles: midjourney
        // (stroke-only theSVG mark, unrasterizable without librsvg) and apple-one (a service bundle
        // with no App Store app icon to source). Everything else resolves to a real icon.
        let uncovered = ["midjourney", "apple-one"]
        for slug in uncovered {
            let brand = ServiceCatalog.brand(serviceKey: slug, name: "")
            #expect(brand?.iconAssetName == nil, "\(slug) has no bundled icon")
        }
    }

    @Test func resolvesExtendedNamesByLongestPrefix() {
        // An extended label still resolves to its base brand via the prefix fallback.
        #expect(ServiceCatalog.brand(serviceKey: nil, name: "Claude Code")?.slug == "claude")
        #expect(ServiceCatalog.brand(serviceKey: nil, name: "Anthropic")?.slug == "claude")
        #expect(ServiceCatalog.brand(serviceKey: nil, name: "Spotify Premium")?.slug == "spotify")
    }

    @Test func prefixFallbackIgnoresShortKeysAndUnrelatedNames() {
        // "Ghost" must not hit github's short "gh" alias, and a truly unknown name stays nil.
        #expect(ServiceCatalog.brand(serviceKey: nil, name: "Ghost") == nil)
        #expect(ServiceCatalog.brand(serviceKey: nil, name: "Wat") == nil)
    }
}
