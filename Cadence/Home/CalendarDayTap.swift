import Foundation

/// What a tap on a calendar day resolves to. Pure and total over any `MonthCalendar.Day`:
/// a chargeless or padding cell is `.none`, one charge opens detail, several open the menu.
enum CalendarDayTap: Equatable {
    case none
    case detail(Subscription)
    case disambiguate([Subscription])

    static func outcome(for day: MonthCalendar.Day) -> CalendarDayTap {
        let subscriptions = day.markers.map(\.subscription)
        switch subscriptions.count {
        case 0: return .none
        case 1: return .detail(subscriptions[0])
        default: return .disambiguate(subscriptions)
        }
    }
}
