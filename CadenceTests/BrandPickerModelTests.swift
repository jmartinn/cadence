@testable import Cadence
import Foundation
import Testing

/// Pure picker logic: alphabetical brand list, case-insensitive name filter, and the
/// "effective brand" label the Icon row shows.
struct BrandPickerModelTests {
    @Test func filteredEmptyReturnsAllSortedByDisplayName() {
        let result = BrandPickerModel.filtered("")
        #expect(result.count == ServiceCatalog.all.count)
        let expected = ServiceCatalog.all.sorted {
            $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
        }
        #expect(result.map(\.slug) == expected.map(\.slug))
    }

    @Test func filteredMatchesDisplayNameCaseInsensitively() {
        let result = BrandPickerModel.filtered("NET")
        #expect(result.contains { $0.slug == "netflix" })
        #expect(!result.contains { $0.slug == "spotify" })
    }

    @Test func effectiveLabelPrefersManualKeyOverName() {
        #expect(BrandPickerModel.effectiveLabel(serviceKey: "spotify", name: "My Stuff") == "Spotify")
    }

    @Test func effectiveLabelFallsBackToNameResolution() {
        #expect(BrandPickerModel.effectiveLabel(serviceKey: nil, name: "Netflix") == "Netflix")
    }

    @Test func effectiveLabelIsNoneWhenNothingResolves() {
        #expect(BrandPickerModel.effectiveLabel(serviceKey: nil, name: "Zzqx Local Gym") == "None")
    }
}
