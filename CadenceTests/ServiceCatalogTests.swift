import SwiftUI
import Testing
@testable import Cadence

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
            keys.append(contentsOf: brand.aliases.map(ServiceCatalog.normalize))
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
}
