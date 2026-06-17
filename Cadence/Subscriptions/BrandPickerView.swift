import SwiftUI

/// Pure picker logic, unit-tested without SwiftUI (mirrors `SubscriptionListPresenter`).
enum BrandPickerModel {
    /// All brands (or those matching `query` by display name), sorted alphabetically.
    static func filtered(_ query: String, in brands: [ServiceBrand] = ServiceCatalog.all) -> [ServiceBrand] {
        let sorted = brands.sorted {
            $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
        }
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return sorted }
        return sorted.filter { $0.displayName.localizedCaseInsensitiveContains(trimmed) }
    }

    /// The label for the form's Icon row: the effective brand's display name, or "None".
    static func effectiveLabel(serviceKey: String?, name: String) -> String {
        ServiceCatalog.brand(serviceKey: serviceKey, name: name)?.displayName ?? "None"
    }
}

/// Searchable list to assign a subscription's brand logo. Selecting a brand sets the bound
/// `serviceKey`; "Automatic" clears it (back to name resolution). No free-form input, no uploads.
struct BrandPickerView: View {
    @Binding var serviceKey: String?
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""

    var body: some View {
        List {
            Button {
                serviceKey = nil
                dismiss()
            } label: {
                HStack {
                    Text("Automatic (match by name)").foregroundStyle(.primary)
                    Spacer()
                    if serviceKey == nil {
                        Image(systemName: "checkmark").foregroundStyle(.tint)
                    }
                }
            }
            ForEach(BrandPickerModel.filtered(search), id: \.slug) { brand in
                Button {
                    serviceKey = brand.slug
                    dismiss()
                } label: {
                    HStack(spacing: 12) {
                        ServiceIcon(serviceKey: brand.slug, name: brand.displayName, size: 28)
                        Text(brand.displayName).foregroundStyle(.primary)
                        Spacer()
                        if serviceKey == brand.slug {
                            Image(systemName: "checkmark").foregroundStyle(.tint)
                        }
                    }
                }
            }
        }
        .searchable(text: $search)
        .navigationTitle("Icon")
        .navigationBarTitleDisplayMode(.inline)
    }
}
