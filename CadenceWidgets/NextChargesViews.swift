import CadenceKit
import SwiftUI
import WidgetKit

/// Routes to the right layout per family.
struct NextChargesEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: NextChargesEntry

    var body: some View {
        switch family {
        case .systemSmall: SmallChargeView(charge: entry.charges.first)
        default: MediumChargesView(charges: Array(entry.charges.prefix(3)))
        }
    }
}

/// Small: the single next charge, big and glanceable.
struct SmallChargeView: View {
    let charge: UpcomingCharge?

    var body: some View {
        if let charge {
            VStack(alignment: .leading, spacing: 6) {
                ServiceIcon(serviceKey: charge.serviceKey, name: charge.name, size: 40)
                Spacer(minLength: 0)
                Text(charge.name).font(.headline).lineLimit(1)
                Text(PriceText.inlineString(charge.amount)).font(.subheadline).bold()
                Text(charge.date, style: .relative).font(.caption).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        } else {
            EmptyChargesView()
        }
    }
}

/// Medium: the next few charges as a list.
struct MediumChargesView: View {
    let charges: [UpcomingCharge]

    var body: some View {
        if charges.isEmpty {
            EmptyChargesView()
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Text("Upcoming").font(.headline)
                ForEach(Array(charges.enumerated()), id: \.offset) { _, charge in
                    HStack(spacing: 10) {
                        ServiceIcon(serviceKey: charge.serviceKey, name: charge.name, size: 28)
                        Text(charge.name).font(.subheadline).lineLimit(1)
                        Spacer(minLength: 4)
                        VStack(alignment: .trailing, spacing: 1) {
                            Text(PriceText.inlineString(charge.amount)).font(.subheadline).bold()
                            Text(charge.date, format: .dateTime.month(.abbreviated).day())
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}

/// Shown when there are no upcoming charges (never a blank tile — HIG).
struct EmptyChargesView: View {
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "checkmark.circle").font(.title2).foregroundStyle(.secondary)
            Text("No upcoming charges").font(.subheadline).foregroundStyle(.secondary)
            Text("Add a subscription").font(.caption2).foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .multilineTextAlignment(.center)
    }
}
