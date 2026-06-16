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
}
