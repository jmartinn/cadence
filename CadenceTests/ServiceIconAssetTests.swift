@testable import Cadence
import Testing
import UIKit

/// Guards against catalog/asset drift: every brand that *declares* a logo must have the bundled
/// app icon to back it, and overall coverage must not silently regress below today's floor.
struct ServiceIconAssetTests {
    @Test func everyDeclaredLogoAssetIsBundled() {
        for brand in ServiceCatalog.all {
            guard let asset = brand.iconAssetName else { continue }
            #expect(UIImage(named: asset) != nil, "missing bundled asset for \(brand.slug): \(asset)")
        }
    }

    @Test func coverageDoesNotRegressBelowFloor() {
        let covered = ServiceCatalog.all.filter { $0.iconAssetName != nil }.count
        #expect(covered >= 51, "logo coverage regressed below the current floor (51); got \(covered)")
    }
}
