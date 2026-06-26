import SwiftData
import SwiftUI

/// The app's 3-tab shell. Home (Slice 6) and Subscriptions (Slices 4–5) are real; Transactions
/// (milestone 2) is a placeholder. A shared `TabRouter` lets Home's "See all" switch tabs.
struct RootTabView: View {
    @State private var router = TabRouter()
    @AppStorage(AccentTheme.storageKey) private var accent: AccentTheme = .default
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        @Bindable var router = router
        TabView(selection: $router.selection) {
            HomeView()
                .tabItem { Label("Home", systemImage: "house") }
                .tag(TabRouter.home)

            SubscriptionsView()
                .tabItem { Label("Subscriptions", systemImage: "creditcard") }
                .tag(TabRouter.subscriptions)

            TransactionsPlaceholderView()
                .tabItem { Label("Transactions", systemImage: "arrow.left.arrow.right") }
                .tag(TabRouter.transactions)
        }
        .environment(router)
        .tint(accent.color)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                WidgetRefresher.refresh(context: modelContext)
                Task { @MainActor in await ReminderCoordinator().reschedule(context: modelContext) }
            }
        }
    }
}

#if DEBUG
#Preview {
    let container = CadenceStore.inMemory()
    SampleSubscriptions.seed(into: container.mainContext)
    return RootTabView()
        .modelContainer(container)
}
#endif
