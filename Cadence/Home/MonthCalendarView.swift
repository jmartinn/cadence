import SwiftUI

/// Read-only month grid. Renders `MonthCalendar.weeks`: weekday header, day numbers, charge-day
/// monograms, the blue debit badge for card subscriptions, today's filled tile, and an inert
/// dashed "+" on the first trailing padding cell (the live "+" is deferred).
struct MonthCalendarView: View {
    let weeks: [MonthCalendar.Week]
    var calendar: Calendar = .current
    var onTapDay: (MonthCalendar.Day) -> Void = { _ in }
    var onTapAdd: () -> Void = {}

    private let columns = Array(repeating: GridItem(.flexible(), spacing: Space.xs), count: 7)
    private static let weekdays = ["M", "T", "W", "T", "F", "S", "S"]

    private var flatDays: [MonthCalendar.Day] { weeks.flatMap(\.days) }
    private var firstTrailingPaddingID: Date? {
        flatDays.first { !$0.isInMonth && $0.date > (flatDays.first { $0.isInMonth }?.date ?? .distantPast) }?.id
    }

    var body: some View {
        VStack(spacing: Space.sm) {
            LazyVGrid(columns: columns, spacing: Space.sm) {
                ForEach(Array(Self.weekdays.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol).font(.system(size: 13, weight: .medium)).foregroundColor(.secondary)
                }
            }
            LazyVGrid(columns: columns, spacing: Space.sm) {
                ForEach(flatDays) { day in
                    CalendarDayCell(day: day, calendar: calendar,
                                    showsAddAffordance: day.id == firstTrailingPaddingID,
                                    onTapDay: onTapDay, onTapAdd: onTapAdd)
                }
            }
        }
    }
}

/// One calendar cell. In-month days show the number (+ monogram + debit badge for charge days);
/// today is a filled tile with a dot; the designated trailing pad cell draws the inert dashed "+".
struct CalendarDayCell: View {
    let day: MonthCalendar.Day
    let calendar: Calendar
    var showsAddAffordance: Bool = false
    var onTapDay: (MonthCalendar.Day) -> Void = { _ in }
    var onTapAdd: () -> Void = {}

    private static let a11yDateFormatter: DateFormatter = {
        let f = DateFormatter(); f.setLocalizedDateFormatFromTemplate("MMMMd"); return f
    }()

    private var number: String {
        day.isInMonth ? "\(calendar.component(.day, from: day.date))" : ""
    }

    private var chargeAccessibilityLabel: String {
        let when = Self.a11yDateFormatter.string(from: day.date)
        let names = day.markers.map(\.serviceName)
        return names.count == 1 ? "\(names[0]), \(when)" : "\(names.count) charges, \(when)"
    }

    var body: some View {
        let cell = ZStack(alignment: .topTrailing) {
            background
            content
            if day.isToday { dot.padding(6) }
            if day.markers.first?.hasCard == true { debitBadge.padding(4) }
        }
        .frame(height: 56)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())

        if showsAddAffordance {
            Button(action: onTapAdd) { cell }
                .buttonStyle(.plain)
                .accessibilityLabel("Add subscription")
        } else if !day.markers.isEmpty {
            Button { onTapDay(day) } label: { cell }
                .buttonStyle(.plain)
                .accessibilityLabel(chargeAccessibilityLabel)
        } else {
            cell
        }
    }

    @ViewBuilder private var background: some View {
        if day.isToday {
            RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.primary)
        } else if !day.markers.isEmpty {
            RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(.secondarySystemFill))
        } else if showsAddAffordance {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [4]))
                .foregroundColor(Color(.tertiaryLabel))
        }
    }

    @ViewBuilder private var content: some View {
        if showsAddAffordance {
            Image(systemName: "plus").font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(.tertiaryLabel))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            VStack(spacing: Space.xs) {
                Text(number)
                    .font(.system(size: 15, weight: day.isToday ? .bold : .regular))
                    .foregroundColor(day.isToday ? Color(.systemBackground) : .primary)
                if let marker = day.markers.first {
                    SubscriptionMonogram(serviceKey: marker.subscription.serviceKey, name: marker.serviceName, size: 18)
                        .overlay(extraCountBadge)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder private var extraCountBadge: some View {
        if day.markers.count > 1 {
            Text("+\(day.markers.count - 1)")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(Color(.systemBackground))
                .padding(2)
                .background(Circle().fill(Color.primary))
                .offset(x: 10, y: -8)
        }
    }

    private var dot: some View {
        Circle().fill(Color.red).frame(width: 6, height: 6)
    }

    /// Blue circular badge with the down-left arrow = "renews & auto-debits to card".
    private var debitBadge: some View {
        Image(systemName: "arrow.down.left")
            .font(.system(size: 8, weight: .bold))
            .foregroundColor(.white)
            .frame(width: 16, height: 16)
            .background(Circle().fill(Color.blue))
    }
}

#if DEBUG
#Preview {
    let cal: Calendar = { var c = Calendar(identifier: .gregorian); c.timeZone = .current; return c }()
    let subs = SampleSubscriptions.makeAll()
    let weeks = MonthCalendar.weeks(for: .now, subscriptions: subs, today: .now, calendar: cal)
    return MonthCalendarView(weeks: weeks, calendar: cal).padding()
}
#endif
