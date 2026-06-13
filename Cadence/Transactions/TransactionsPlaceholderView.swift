import SwiftUI

/// Placeholder for the Transactions tab. Built out in milestone 2.
struct TransactionsPlaceholderView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Transactions",
                systemImage: "arrow.left.arrow.right",
                description: Text("Coming in milestone 2")
            )
            .navigationTitle("Transactions")
        }
    }
}

#Preview {
    TransactionsPlaceholderView()
}
