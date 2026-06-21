import CadenceKit
import Testing

struct ReminderLeadTimeTests {
    @Test func daysBeforeMapsEachCase() {
        #expect(ReminderLeadTime.sameDay.daysBefore == 0)
        #expect(ReminderLeadTime.oneDay.daysBefore == 1)
        #expect(ReminderLeadTime.twoDays.daysBefore == 2)
        #expect(ReminderLeadTime.threeDays.daysBefore == 3)
        #expect(ReminderLeadTime.oneWeek.daysBefore == 7)
    }

    @Test func displayNameMapsEachCase() {
        #expect(ReminderLeadTime.sameDay.displayName == "On the day")
        #expect(ReminderLeadTime.oneDay.displayName == "1 day before")
        #expect(ReminderLeadTime.twoDays.displayName == "2 days before")
        #expect(ReminderLeadTime.threeDays.displayName == "3 days before")
        #expect(ReminderLeadTime.oneWeek.displayName == "1 week before")
    }

    @Test func relativePhraseReadsNaturally() {
        #expect(ReminderLeadTime.sameDay.relativePhrase == "today")
        #expect(ReminderLeadTime.oneDay.relativePhrase == "tomorrow")
        #expect(ReminderLeadTime.twoDays.relativePhrase == "in 2 days")
        #expect(ReminderLeadTime.threeDays.relativePhrase == "in 3 days")
        #expect(ReminderLeadTime.oneWeek.relativePhrase == "in a week")
    }

    @Test func rawValuesAreStableForAppStorage() {
        // The @AppStorage contract: rawValues must never drift.
        #expect(ReminderLeadTime(rawValue: "oneDay") == .oneDay)
        #expect(ReminderLeadTime.allCases.count == 5)
    }
}
