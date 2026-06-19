import CadenceKit
import SwiftData
import SwiftUI

/// The Subscriptions tab — Cadence's first real screen. Reads subscriptions reactively via
/// `@Query`, derives display order with `SubscriptionListPresenter`, and totals with `Forecaster`.
/// MV architecture: the mutable state is the selected sort mode and category filter.
struct SubscriptionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Subscription.name) private var subscriptions: [Subscription]
    @State private var sort: SubscriptionSort = .nextCharge
    @State private var categoryFilter: SubscriptionCategory? = nil
    @State private var showingAdd = false

    private var today: Date { .now }
    private var calendar: Calendar { .current }

    private var availableCategories: [SubscriptionCategory] {
        SubscriptionListPresenter.availableCategories(in: subscriptions)
    }

    private var effectiveFilter: SubscriptionCategory? {
        SubscriptionListPresenter.effectiveCategory(categoryFilter, among: availableCategories)
    }

    private var filteredSubscriptions: [Subscription] {
        SubscriptionListPresenter.filtered(subscriptions, by: effectiveFilter)
    }

    private var visibleSubscriptions: [Subscription] {
        SubscriptionListPresenter.sorted(filteredSubscriptions, by: sort, today: today, calendar: calendar)
    }

    private var forecaster: Forecaster {
        // Totals are anchor-independent and filter to `.active` internally, so a neutral
        // (0, .distantPast) anchor is purely a constructor requirement. Built from the filtered
        // set so the summary card follows the active category filter.
        Forecaster(anchorBalance: 0, asOfDate: .distantPast, subscriptions: filteredSubscriptions.map(\.plan))
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
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !subscriptions.isEmpty { sortMenu }
                }
                #if DEBUG
                ToolbarItem(placement: .topBarTrailing) {
                    Button { seedSampleData() } label: { Image(systemName: "ladybug") }
                        .accessibilityLabel("Seed sample data")
                }
                #endif
            }
        }
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: Space.lg) {
                SubscriptionSummaryCard(
                    monthly: forecaster.monthlyTotal,
                    yearly: forecaster.yearlyTotal,
                    title: effectiveFilter?.displayName
                )
                filterControl
                LazyVStack(spacing: Space.md) {
                    ForEach(visibleSubscriptions) { sub in
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
            .padding(Space.lg)
            .padding(.bottom, 96) // clear the FAB (on-grid: 24×4, larger than the named scale)
        }
    }

    /// One capsule pill, shared by the Sort and Filter rows so they stay visually identical.
    private func pill(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .padding(.horizontal, Space.md)
                .padding(.vertical, Space.sm)
                .background(isSelected ? Color.primary : Color(.tertiarySystemFill))
                .foregroundColor(isSelected ? Color(.systemBackground) : .secondary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    /// Sort options as a navigation-bar pull-down menu (HIG's canonical "Sort by" pull-down),
    /// replacing the inline pill row so the Filter row is the only on-screen control.
    private var sortMenu: some View {
        Menu {
            Picker("Sort by", selection: $sort) {
                ForEach(SubscriptionSort.allCases) { option in
                    Text(option.title).tag(option)
                }
            }
        } label: {
            Label("Sort by", systemImage: "arrow.up.arrow.down")
        }
        .accessibilityLabel("Sort by")
    }

    /// Capsule filter row: "All" + one chip per populated category, in canonical order.
    /// Rendered only when there are at least two categories to choose between; horizontally
    /// scrolls because the category set can be long. Chips use the shared `pill` styling.
    @ViewBuilder private var filterControl: some View {
        if SubscriptionListPresenter.shouldOfferFilter(in: subscriptions) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Space.sm) {
                    Text("Filter")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    pill("All", isSelected: effectiveFilter == nil) { categoryFilter = nil }
                    ForEach(availableCategories, id: \.self) { category in
                        pill(category.displayName, isSelected: effectiveFilter == category) {
                            categoryFilter = category
                        }
                    }
                }
            }
        }
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
                // Monochrome glyph on clear glass; Color.primary adapts (near-black light /
                // near-white dark). No fill or shadow — the glass supplies the elevation.
                .foregroundStyle(Color.primary)
                .frame(width: 58, height: 58)
                .glassEffect(.regular.interactive(), in: .circle)
        }
        .buttonStyle(.plain) // suppress the default gray-dim; interactive glass owns the press feel
        .padding(.bottom, Space.xl)
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
