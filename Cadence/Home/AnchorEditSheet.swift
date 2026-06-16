import SwiftData
import SwiftUI

/// Sheet to set the balance anchor + recurring income. Driven by `AnchorDraft`; Save disabled
/// until the draft validates. The payday field appears only once income is entered. MV: no view-model.
struct AnchorEditSheet: View {
    let anchor: BalanceAnchor?
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var draft: AnchorDraft

    init(anchor: BalanceAnchor?) {
        self.anchor = anchor
        if let anchor {
            _draft = State(initialValue: AnchorDraft(from: anchor))
        } else {
            _draft = State(initialValue: .empty(now: .now))
        }
    }

    private var incomeEntered: Bool {
        !draft.monthlyIncome.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Balance") {
                    TextField("Current balance", text: $draft.balance)
                        .keyboardType(.decimalPad)
                    DatePicker("As of", selection: $draft.asOfDate, displayedComponents: .date)
                }
                Section {
                    TextField("Monthly income", text: $draft.monthlyIncome)
                        .keyboardType(.decimalPad)
                    if incomeEntered {
                        DatePicker("Payday", selection: $draft.payday, displayedComponents: .date)
                    }
                } header: {
                    Text("Income")
                } footer: {
                    Text("Optional. Used to project how the month ends.")
                }
            }
            .navigationTitle("Your balance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(!draft.isValid)
                }
            }
        }
    }

    private func save() {
        do { try draft.apply(via: modelContext) }
        catch { assertionFailure("AnchorEditSheet save failed: \(error)") }
        dismiss()
    }
}

#if DEBUG
#Preview("New") {
    AnchorEditSheet(anchor: nil).modelContainer(CadenceStore.inMemory())
}
#endif
