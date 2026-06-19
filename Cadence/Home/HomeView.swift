import SwiftData
import SwiftUI

/// The Home tab: forecast dashboard for the displayed month. MV — derivation lives in `HomeSummary`
/// and `MonthCalendar`; the view only composes. Reads subscriptions and the anchor via `@Query`.
/// Navigation is forward-only: `displayedMonth` is always >= the current calendar month.
struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(TabRouter.self) private var router
    @Query private var subscriptions: [Subscription]
    @Query(sort: \BalanceAnchor.asOfDate, order: .reverse) private var anchors: [BalanceAnchor]
    @State private var showingAnchorSheet = false
    @State private var displayedMonth: Date = MonthNavigation.startOfMonth(for: .now, calendar: .current)
    @State private var path = NavigationPath()
    @State private var disambiguating: MonthCalendar.Day?
    @State private var showingAdd = false

    private var today: Date { .now }
    private var calendar: Calendar { .current }
    private var anchor: BalanceAnchor? { anchors.first }

    private var isViewingCurrentMonth: Bool {
        calendar.isDate(displayedMonth, equalTo: today, toGranularity: .month)
    }

    private static let monthFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "MMMM"; return f
    }()

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter(); f.setLocalizedDateFormatFromTemplate("MMMMd"); return f
    }()

    private var disambiguationTitle: String {
        guard let day = disambiguating else { return "" }
        return "Charges on \(Self.dayFormatter.string(from: day.date))"
    }

    private var isDisambiguating: Binding<Bool> {
        Binding(get: { disambiguating != nil },
                set: { presented in if !presented { disambiguating = nil } })
    }

    private var summary: HomeSummary {
        HomeSummary.make(subscriptions: subscriptions, anchor: anchor,
                         referenceDate: displayedMonth, today: today, calendar: calendar)
    }

    private var weeks: [MonthCalendar.Week] {
        MonthCalendar.weeks(for: displayedMonth, subscriptions: subscriptions,
                            today: today, calendar: calendar)
    }

    private var renewing: [HomeSummary.RenewingItem] {
        HomeSummary.renewing(subscriptions: subscriptions,
                             referenceDate: displayedMonth, calendar: calendar)
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: Space.xl) {
                    HomeMonthHeader(
                        month: displayedMonth,
                        canGoBack: MonthNavigation.canGoBack(from: displayedMonth, today: today, calendar: calendar),
                        onPrevious: {
                            displayedMonth = MonthNavigation.advanced(from: displayedMonth, by: -1,
                                                                      today: today, calendar: calendar)
                        },
                        onNext: {
                            displayedMonth = MonthNavigation.advanced(from: displayedMonth, by: 1,
                                                                      today: today, calendar: calendar)
                        },
                        onProfile: { path.append(SettingsRoute.settings) }
                    )
                    SpendingHeadline(monthlyTotal: summary.monthlyTotal)
                    if isViewingCurrentMonth {
                        PaidSummaryView(paid: summary.paid, total: summary.total,
                                        paidAmount: summary.paidAmount, clusterIcons: summary.clusterIcons)
                            .font(.system(size: 15))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Space.md)
                    }
                    ForecastLineView(projected: summary.projectedEndOfMonth) { showingAnchorSheet = true }
                        .padding(.horizontal, Space.md)
                    MonthCalendarView(
                        weeks: weeks,
                        calendar: calendar,
                        onTapDay: { day in
                            switch CalendarDayTap.outcome(for: day) {
                            case .none: break
                            case let .detail(sub): path.append(sub)
                            case .disambiguate: disambiguating = day
                            }
                        },
                        onTapAdd: { showingAdd = true }
                    )
                    if !renewing.isEmpty {
                        RenewingSection(
                            title: isViewingCurrentMonth
                                ? "Renewing this month"
                                : "Renewing in \(Self.monthFormatter.string(from: displayedMonth))",
                            items: renewing
                        ) { router.selection = TabRouter.subscriptions }
                    }
                }
                .padding(Space.lg)
                .animation(.easeInOut(duration: 0.2), value: displayedMonth)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationDestination(for: Subscription.self) { SubscriptionDetailView(subscription: $0) }
            .navigationDestination(for: SettingsRoute.self) { _ in SettingsView() }
            .sheet(isPresented: $showingAnchorSheet) { AnchorEditSheet(anchor: anchor) }
            .sheet(isPresented: $showingAdd) { SubscriptionFormView(mode: .add) }
            .confirmationDialog(disambiguationTitle, isPresented: isDisambiguating,
                                titleVisibility: .visible, presenting: disambiguating) { day in
                ForEach(day.markers.map(\.subscription)) { sub in
                    Button(sub.name) { path.append(sub) }
                }
            }
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
