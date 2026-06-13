import SwiftUI

/// Placeholder for the Home tab. The real forecast + calendar screen arrives in Slice 6.
struct HomePlaceholderView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Home",
                systemImage: "house",
                description: Text("Coming in Slice 6")
            )
            .navigationTitle("Home")
        }
    }
}

#Preview {
    HomePlaceholderView()
}
