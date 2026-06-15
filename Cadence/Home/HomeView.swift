import SwiftUI
import SwiftData

/// The Home tab: forecast dashboard for the current month. MV — derivation lives in `HomeSummary`
/// and `MonthCalendar`; the view only composes. Reads subscriptions and the anchor via `@Query`.
struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(TabRouter.self) private var router
    @Query private var subscriptions: [Subscription]
    @Query(sort: \BalanceAnchor.asOfDate, order: .reverse) private var anchors: [BalanceAnchor]
    @State private var showingAnchorSheet = false

    private var today: Date { .now }
    private var calendar: Calendar { .current }
    private var anchor: BalanceAnchor? { anchors.first }

    private var summary: HomeSummary {
        HomeSummary.make(subscriptions: subscriptions, anchor: anchor, today: today, calendar: calendar)
    }
    private var weeks: [MonthCalendar.Week] {
        MonthCalendar.weeks(for: today, subscriptions: subscriptions, today: today, calendar: calendar)
    }
    private var renewing: [HomeSummary.RenewingItem] {
        HomeSummary.renewing(subscriptions: subscriptions, today: today, calendar: calendar)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Space.xl) {
                    HomeMonthHeader(month: today)
                    SpendingHeadline(monthlyTotal: summary.monthlyTotal)
                    PaidSummaryView(paid: summary.paid, total: summary.total,
                                    paidAmount: summary.paidAmount, clusterNames: summary.clusterNames)
                        .font(.system(size: 15))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Space.md)
                    ForecastLineView(projected: summary.projectedEndOfMonth) { showingAnchorSheet = true }
                        .padding(.horizontal, Space.md)
                    MonthCalendarView(weeks: weeks, calendar: calendar)
                    if !renewing.isEmpty {
                        RenewingSection(items: renewing) { router.selection = TabRouter.subscriptions }
                    }
                }
                .padding(Space.lg)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationDestination(for: Subscription.self) { SubscriptionDetailView(subscription: $0) }
            .sheet(isPresented: $showingAnchorSheet) { AnchorEditSheet(anchor: anchor) }
        }
    }
}

#if DEBUG
#Preview {
    let container = CadenceStore.inMemory()
    SampleSubscriptions.seed(into: container.mainContext)
    _ = try? container.mainContext.setAnchor(
        balance: Decimal(string: "1116.00")!, asOfDate: .now,
        monthlyIncome: Decimal(string: "0.00")!, incomePayday: .distantPast
    )
    return HomeView()
        .environment(TabRouter())
        .modelContainer(container)
}
#endif
