import CadenceKit
import SwiftData
import SwiftUI

/// Read-only detail for one subscription (the Figma detail frame) plus its lifecycle actions.
/// `@Bindable` so status mutations and edits re-render live. MV: no view-model.
struct SubscriptionDetailView: View {
    @Bindable var subscription: Subscription
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var showingEdit = false
    @State private var showingCancelConfirm = false

    private var calendar: Calendar { .current }
    private var today: Date { .now }

    private static let chargeDateFormatter: DateFormatter = {
        let f = DateFormatter(); f.setLocalizedDateFormatFromTemplate("MMMMd"); return f
    }()

    private static let nextChargeFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateStyle = .medium; return f
    }()

    var body: some View {
        ScrollView {
            VStack(spacing: Space.xl) {
                header
                infoCard
                addOnsSection
                recentCharges
                actions
            }
            .padding(Space.lg)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingEdit = true } label: { Image(systemName: "pencil") }
                    .accessibilityLabel("Edit subscription")
            }
        }
        .sheet(isPresented: $showingEdit) {
            // On delete the model is tombstoned; pop this detail so we don't strand the user on
            // a stale snapshot. The sheet dismisses itself first, then this dismiss pops the push.
            SubscriptionFormView(mode: .edit(subscription), onDelete: { dismiss() })
        }
        .confirmationDialog("Cancel this subscription?", isPresented: $showingCancelConfirm, titleVisibility: .visible) {
            Button("Cancel subscription", role: .destructive) { setStatus(.ended) }
            Button("Keep it", role: .cancel) {}
        } message: {
            Text("It stops counting toward your forecast. You can reactivate it later.")
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(spacing: Space.md) {
            ServiceIcon(serviceKey: subscription.serviceKey, name: subscription.name, size: 72)
            Text(subscription.name)
                .font(.system(size: 24, weight: .bold))
            statusPill
            PriceText(subscription.amount, symbolPosition: .leading, suffix: cycleSuffix,
                      wholeSize: 48, symbolSize: 28, centsSize: 22,
                      symbolLift: .capAligned, centsLift: .capAligned)
        }
    }

    private var statusPill: some View {
        HStack(spacing: Space.sm) {
            Circle().fill(statusColor).frame(width: 8, height: 8)
            Text(statusText).font(.system(size: 14, weight: .medium))
        }
        .padding(.horizontal, Space.md)
        .padding(.vertical, Space.sm)
        .background(Color(.secondarySystemFill), in: Capsule())
    }

    private var statusText: String {
        switch subscription.status {
        case .active: return "Active"
        case .paused: return "Paused"
        case .ended: return "Ended"
        }
    }

    private var statusColor: Color {
        switch subscription.status {
        case .active: return .green
        case .paused: return .orange
        case .ended: return .gray
        }
    }

    private var cycleSuffix: String { subscription.billingCycle == .monthly ? "/m" : "/y" }

    // MARK: Info card

    private var infoCard: some View {
        VStack(spacing: 0) {
            InfoRow(systemImage: "arrow.triangle.2.circlepath", label: "Billing cycle", value: cycleName)
            Divider().padding(.leading, Space.lg)
            InfoRow(systemImage: "calendar", label: "Next charge", value: nextChargeText)
            Divider().padding(.leading, Space.lg)
            InfoRow(systemImage: "tag", label: "Category", value: subscription.category)
            if let parent = subscription.parent {
                Divider().padding(.leading, Space.lg)
                NavigationLink(value: parent) {
                    InfoRow(systemImage: "square.stack.3d.up", label: "Part of", value: parent.name)
                }
                .buttonStyle(.plain)
            }
            if let payment = paymentText {
                Divider().padding(.leading, Space.lg)
                InfoRow(systemImage: "creditcard", label: "Payment method", value: payment)
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var cycleName: String { subscription.billingCycle == .monthly ? "Monthly" : "Yearly" }

    private var nextChargeText: String {
        // Only an active subscription has a meaningful upcoming charge; paused/ended ones won't
        // bill, so a future date would mislead. (Recent charges stay — they're past history.)
        guard subscription.status == .active,
              let next = SubscriptionListPresenter.nextCharge(for: subscription, after: today, calendar: calendar)
        else {
            return "—"
        }
        return Self.nextChargeFormatter.string(from: next)
    }

    private var paymentText: String? {
        guard let brand = subscription.paymentBrand, let last4 = subscription.paymentLast4,
              !brand.isEmpty, !last4.isEmpty else { return nil }
        return "\(brand) •••• \(last4)"
    }

    // MARK: Add-ons section

    private var sortedAddOns: [Subscription] {
        subscription.addOns.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    private var combinedTotalText: String {
        let total = SubscriptionListPresenter.combinedMonthly(for: subscription)
        let code = Locale.current.currency?.identifier ?? "USD"
        return "\(total.formatted(.currency(code: code)))/mo with add-ons"
    }

    @ViewBuilder private var addOnsSection: some View {
        if !subscription.addOns.isEmpty {
            VStack(alignment: .leading, spacing: Space.md) {
                Text("Add-ons").font(.system(size: 18, weight: .bold))
                VStack(spacing: 0) {
                    ForEach(sortedAddOns) { addOn in
                        NavigationLink(value: addOn) {
                            HStack(spacing: Space.md) {
                                ServiceIcon(serviceKey: addOn.serviceKey, name: addOn.name)
                                Text(addOn.name)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                                Spacer(minLength: Space.sm)
                                PriceText(addOn.amount, symbolPosition: .trailing,
                                          suffix: addOn.billingCycle == .monthly ? "/m" : "/y",
                                          wholeSize: 16, symbolSize: 16, centsSize: 11)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color(.tertiaryLabel))
                            }
                            .padding(Space.lg)
                        }
                        .buttonStyle(.plain)
                        if addOn.persistentModelID != sortedAddOns.last?.persistentModelID {
                            Divider().padding(.leading, Space.lg)
                        }
                    }
                }
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                Text(combinedTotalText)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: Recent charges

    private var charges: [RecentCharges.Charge] {
        RecentCharges.recent(for: subscription, asOf: today, calendar: calendar)
    }

    @ViewBuilder private var recentCharges: some View {
        if !charges.isEmpty {
            VStack(alignment: .leading, spacing: Space.md) {
                Text("Recent charges").font(.system(size: 18, weight: .bold))
                VStack(spacing: 0) {
                    ForEach(charges) { charge in
                        HStack {
                            VStack(alignment: .leading, spacing: Space.xs) {
                                Text(Self.chargeDateFormatter.string(from: charge.date))
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Posted")
                                    .font(.system(size: 13))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            PriceText(charge.amount, symbolPosition: .trailing,
                                      wholeSize: 16, symbolSize: 16, centsSize: 11)
                        }
                        .padding(Space.lg)
                        if charge.id != charges.last?.id {
                            Divider().padding(.leading, Space.lg)
                        }
                    }
                }
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: Actions

    private var actions: some View {
        VStack(spacing: Space.md) {
            switch subscription.status {
            case .active:
                actionButton("Pause subscription", systemImage: "pause.fill") { setStatus(.paused) }
                cancelButton
            case .paused:
                actionButton("Resume subscription", systemImage: "play.fill") { setStatus(.active) }
                cancelButton
            case .ended:
                actionButton("Reactivate subscription", systemImage: "arrow.clockwise") { setStatus(.active) }
            }
        }
    }

    private func actionButton(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Space.lg)
        }
        .background(Color(.secondarySystemFill), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .foregroundStyle(.primary)
    }

    private var cancelButton: some View {
        Button(role: .destructive) { showingCancelConfirm = true } label: {
            Label("Cancel subscription", systemImage: "xmark")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Space.lg)
        }
        .background(Color.red.opacity(0.12), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .foregroundStyle(.red)
    }

    private func setStatus(_ status: SubscriptionStatus) {
        subscription.status = status
        try? modelContext.save()
    }
}

#if DEBUG
#Preview {
    let container = CadenceStore.inMemory()
    let sub = Subscription(
        name: "Netflix", amount: Decimal(string: "17.99")!, billingCycle: .monthly,
        anchorDate: Date(timeIntervalSince1970: 1_733_270_400), status: .active,
        category: "Entertainment", paymentBrand: "Visa", paymentLast4: "4821"
    )
    container.mainContext.insert(sub)
    return NavigationStack { SubscriptionDetailView(subscription: sub) }
        .modelContainer(container)
}
#endif
