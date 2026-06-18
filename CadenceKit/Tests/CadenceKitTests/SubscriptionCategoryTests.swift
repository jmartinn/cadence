import CadenceKit
import Testing

struct SubscriptionCategoryTests {
    @Test func hasThirteenCasesWithOtherLast() {
        #expect(SubscriptionCategory.allCases.count == 13)
        #expect(SubscriptionCategory.allCases.last == .other)
    }

    @Test func rawValueRoundTripsForEveryCase() {
        for category in SubscriptionCategory.allCases {
            #expect(SubscriptionCategory(rawValue: category.rawValue) == category)
        }
    }

    @Test func unknownOrBlankRawValueIsNil() {
        #expect(SubscriptionCategory(rawValue: "Streaming") == nil)
        #expect(SubscriptionCategory(rawValue: "") == nil)
    }

    @Test func everyCaseHasNonEmptyDisplayNameAndSymbol() {
        for category in SubscriptionCategory.allCases {
            #expect(!category.displayName.isEmpty)
            #expect(!category.systemImage.isEmpty)
        }
    }

    @Test func knownTitleCaseStringsResolve() {
        #expect(SubscriptionCategory(rawValue: "Entertainment") == .entertainment)
        #expect(SubscriptionCategory(rawValue: "Developer Tools") == .developerTools)
        #expect(SubscriptionCategory(rawValue: "Health & Fitness") == .healthAndFitness)
    }
}
