import SwiftData
import SwiftUI

/// The app's 3-tab shell. Subscriptions is real (Slice 4); Home (Slice 6) and Transactions
/// (milestone 2) are placeholders. Defaults to the Subscriptions tab so the current work is
/// visible on launch.
struct RootTabView: View {
    @State private var selection = 1

    var body: some View {
        TabView(selection: $selection) {
            HomePlaceholderView()
                .tabItem { Label("Home", systemImage: "house") }
                .tag(0)

            SubscriptionsView()
                .tabItem { Label("Subscriptions", systemImage: "creditcard") }
                .tag(1)

            TransactionsPlaceholderView()
                .tabItem { Label("Transactions", systemImage: "arrow.left.arrow.right") }
                .tag(2)
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
