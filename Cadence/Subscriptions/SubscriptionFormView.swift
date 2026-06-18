import CadenceKit
import SwiftData
import SwiftUI

/// Shared Add/Edit sheet. `mode` decides title + save behavior; all editable state lives in a
/// single `SubscriptionDraft`. Save is disabled until the draft validates. Edit mode also offers
/// a destructive Delete (with confirmation). MV: no view-model.
struct SubscriptionFormView: View {
    enum Mode {
        case add
        case edit(Subscription)
    }

    let mode: Mode
    /// Invoked after a successful delete (edit mode only) so the presenter can pop the now-
    /// tombstoned detail screen. `dismiss()` only closes this sheet; it can't pop its presenter.
    var onDelete: (() -> Void)?
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Subscription.name) private var allSubscriptions: [Subscription]
    @State private var draft: SubscriptionDraft
    @State private var showingDeleteConfirm = false

    init(mode: Mode, onDelete: (() -> Void)? = nil) {
        self.mode = mode
        self.onDelete = onDelete
        switch mode {
        case .add:
            _draft = State(initialValue: .empty(now: .now))
        case let .edit(sub):
            _draft = State(initialValue: SubscriptionDraft(from: sub))
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $draft.name)
                    NavigationLink {
                        BrandPickerView(serviceKey: $draft.serviceKey)
                    } label: {
                        HStack(spacing: 12) {
                            ServiceIcon(serviceKey: draft.serviceKey, name: draft.name, size: 28)
                            Text("Icon")
                            Spacer()
                            Text(BrandPickerModel.effectiveLabel(serviceKey: draft.serviceKey, name: draft.name))
                                .foregroundStyle(.secondary)
                        }
                    }
                    TextField("Amount", text: $draft.amount)
                        .keyboardType(.decimalPad)
                    Picker("Billing cycle", selection: $draft.billingCycle) {
                        Text("Monthly").tag(BillingCycle.monthly)
                        Text("Yearly").tag(BillingCycle.yearly)
                    }
                    DatePicker("First charge", selection: $draft.anchorDate, displayedComponents: .date)
                    Picker("Category", selection: $draft.category) {
                        ForEach(SubscriptionCategory.allCases, id: \.self) { category in
                            Label(category.displayName, systemImage: category.systemImage)
                                .tag(category)
                        }
                    }
                }
                Section("Payment method") {
                    TextField("Card brand (e.g. Visa)", text: $draft.paymentBrand)
                    TextField("Last 4 digits", text: $draft.paymentLast4)
                        .keyboardType(.numberPad)
                }
                if showsParentPicker {
                    Section("Part of") {
                        Picker("Parent subscription", selection: $draft.parentID) {
                            Text("None").tag(PersistentIdentifier?.none)
                            ForEach(parentCandidates) { candidate in
                                Text(candidate.name).tag(Optional(candidate.persistentModelID))
                            }
                        }
                    }
                }
                if case .edit = mode {
                    Section {
                        Button("Delete subscription", role: .destructive) {
                            showingDeleteConfirm = true
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!draft.isValid)
                }
            }
            .confirmationDialog("Delete this subscription?", isPresented: $showingDeleteConfirm, titleVisibility: .visible) {
                Button("Delete", role: .destructive) { deleteIfEditing() }
                Button("Keep it", role: .cancel) {}
            } message: {
                Text("This permanently removes it. This can't be undone.")
            }
        }
    }

    private var title: String {
        switch mode {
        case .add: return "New Subscription"
        case .edit: return "Edit Subscription"
        }
    }

    /// The sub being edited (Add mode has none) — used to exclude self and read existing add-ons.
    private var editingSubject: Subscription? {
        if case let .edit(sub) = mode { return sub }
        return nil
    }

    private var showsParentPicker: Bool {
        SubscriptionListPresenter.canHaveParent(editingSubject)
    }

    private var parentCandidates: [Subscription] {
        SubscriptionListPresenter.eligibleParents(for: editingSubject, among: allSubscriptions)
    }

    private func save() {
        let parent = allSubscriptions.first { $0.persistentModelID == draft.parentID }
        switch mode {
        case .add:
            // All values are placeholders that `draft.apply(to:parent:)` overwrites; the Subscription
            // init has no defaults, so we pass throwaways and let the draft be the source of truth.
            let sub = Subscription(name: "", amount: 0, billingCycle: .monthly,
                                   anchorDate: .distantPast, category: "")
            draft.apply(to: sub, parent: parent)
            modelContext.insert(sub)
        case let .edit(sub):
            draft.apply(to: sub, parent: parent)
        }
        persist()
        dismiss()
    }

    private func deleteIfEditing() {
        guard case let .edit(sub) = mode else {
            dismiss()
            return
        }
        modelContext.delete(sub)
        persist()
        dismiss()
        onDelete?()
    }

    /// Best-effort explicit save. SwiftData autosave is the backstop, so a failure here is
    /// deliberately non-fatal; in DEBUG we surface it to catch schema/migration mistakes early.
    private func persist() {
        do {
            try modelContext.save()
        } catch {
            assertionFailure("SubscriptionFormView save failed: \(error)")
        }
    }
}

#if DEBUG
#Preview("Add") {
    SubscriptionFormView(mode: .add)
        .modelContainer(CadenceStore.inMemory())
}
#endif
