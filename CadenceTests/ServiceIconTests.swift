@testable import Cadence
import SwiftUI
import Testing

struct ServiceIconTests {
    @Test func knownBrandWithLogoUsesLogoBranch() {
        let p = ServiceIcon.presentation(serviceKey: "netflix", name: "Netflix")
        guard case let .logo(assetName) = p else {
            Issue.record("expected .logo, got \(p)"); return
        }
        #expect(assetName == "netflix")
    }

    @Test func knownBrandWithoutLogoFallsBackToLetter() {
        // apple-one is in the catalog but has no bundled logo (service bundle, no App Store app icon).
        let p = ServiceIcon.presentation(serviceKey: "apple-one", name: "Apple One")
        guard case .letter = p else {
            Issue.record("expected .letter, got \(p)"); return
        }
    }

    @Test func unknownServiceUsesHashedLetter() {
        let p = ServiceIcon.presentation(serviceKey: nil, name: "Totally Unknown Co")
        guard case .hashedLetter = p else {
            Issue.record("expected .hashedLetter, got \(p)"); return
        }
    }

    @Test func letterForegroundIsBlackOrWhite() {
        // A no-logo catalog brand still renders a contrast-extreme letter on its tile.
        let p = ServiceIcon.presentation(serviceKey: "apple-one", name: "Apple One")
        guard case let .letter(_, foreground) = p else {
            Issue.record("expected .letter"); return
        }
        #expect(foreground == .black || foreground == .white)
    }
}
