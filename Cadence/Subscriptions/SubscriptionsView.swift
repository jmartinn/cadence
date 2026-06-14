import SwiftUI
import SwiftData

/// The Subscriptions tab — Cadence's first real screen. Reads subscriptions reactively via
/// `@Query`, derives display order with `SubscriptionListPresenter`, and totals with `Forecaster`.
/// MV architecture: the only mutable state is the selected sort mode.
struct SubscriptionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Subscription.name) private var subscriptions: [Subscription]
    @State private var sort: SubscriptionSort = .nextCharge
    @State private var showingAdd = false

    private var today: Date { .now }
    private var calendar: Calendar { .current }

    private var orderedSubscriptions: [Subscription] {
        SubscriptionListPresenter.sorted(subscriptions, by: sort, today: today, calendar: calendar)
    }

    private var forecaster: Forecaster {
        // Totals are anchor-independent and filter to `.active` internally, so a neutral
        // (0, .distantPast) anchor is purely a constructor requirement.
        Forecaster(anchorBalance: 0, asOfDate: .distantPast, subscriptions: subscriptions.map(\.plan))
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color(.systemGroupedBackground).ignoresSafeArea()

                if subscriptions.isEmpty {
                    emptyState
                } else {
                    content
                }

                fab
            }
            .navigationTitle("Subscriptions")
            .navigationDestination(for: Subscription.self) { sub in
                SubscriptionDetailView(subscription: sub)
            }
            .sheet(isPresented: $showingAdd) {
                SubscriptionFormView(mode: .add)
            }
            #if DEBUG
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { seedSampleData() } label: { Image(systemName: "ladybug") }
                        .accessibilityLabel("Seed sample data")
                }
            }
            #endif
        }
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: 16) {
                SubscriptionSummaryCard(
                    monthly: forecaster.monthlyTotal,
                    yearly: forecaster.yearlyTotal
                )
                sortControl
                LazyVStack(spacing: 12) {
                    ForEach(orderedSubscriptions) { sub in
                        NavigationLink(value: sub) {
                            SubscriptionRow(
                                subscription: sub,
                                nextCharge: SubscriptionListPresenter.nextCharge(
                                    for: sub, after: today, calendar: calendar
                                )
                            )
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button("Delete", systemImage: "trash", role: .destructive) {
                                modelContext.delete(sub)
                                persist()
                            }
                        }
                    }
                }
            }
            .padding(16)
            .padding(.bottom, 96) // clear the FAB
        }
    }

    private var sortControl: some View {
        HStack(spacing: 8) {
            Text("Sort by")
                .font(.subheadline)
                .foregroundColor(.secondary)
            ForEach(SubscriptionSort.allCases) { option in
                Button {
                    sort = option
                } label: {
                    Text(option.title)
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(sort == option ? Color.primary : Color(.tertiarySystemFill))
                        .foregroundColor(sort == option ? Color(.systemBackground) : .secondary)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No subscriptions yet", systemImage: "calendar")
        } description: {
            Text("Tap + to add your first one and Cadence will start tracking your monthly spend.")
        }
    }

    private var fab: some View {
        Button {
            showingAdd = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 58, height: 58)
                .background(Color.primary)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
        }
        .padding(.bottom, 24)
        .accessibilityLabel("Add subscription")
    }

    /// DEBUG-only action behind the toolbar's ladybug button: seeds sample subscriptions
    /// for previews and on-device testing. Not compiled into release builds.
    private func seedSampleData() {
        #if DEBUG
        SampleSubscriptions.seed(into: modelContext)
        #endif
    }

    /// Best-effort explicit save. SwiftData autosave is the backstop, so a failure here is
    /// deliberately non-fatal; in DEBUG we surface it to catch schema/migration mistakes early.
    private func persist() {
        do {
            try modelContext.save()
        } catch {
            assertionFailure("SubscriptionsView save failed: \(error)")
        }
    }
}

#if DEBUG
#Preview("Populated") {
    let container = CadenceStore.inMemory()
    SampleSubscriptions.seed(into: container.mainContext)
    return SubscriptionsView()
        .modelContainer(container)
}

#Preview("Empty") {
    SubscriptionsView()
        .modelContainer(CadenceStore.inMemory())
}
#endif
