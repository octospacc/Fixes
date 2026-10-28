import SwiftUI
import SwiftData

struct EntryEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: [SortDescriptor(\Consumable.name)])
    private var items: [Consumable]

    @AppStorage("currencyCode") private var currencyCode = Money.currencyCode()

    private let entry: ConsumptionEntry?

    @State private var selectedItemID: UUID?
    @State private var quantity: Int
    @State private var timestamp: Date
    @State private var hasTime: Bool
    @State private var priceText: String
    @State private var note: String
    @State private var confirmingDelete = false

    init(entry: ConsumptionEntry? = nil) {
        self.entry = entry
        _selectedItemID = State(initialValue: entry?.consumable?.id)
        _quantity = State(initialValue: entry?.quantity ?? 1)
        _timestamp = State(initialValue: entry?.timestamp ?? .now)
        _hasTime = State(initialValue: entry?.hasTime ?? true)
        _priceText = State(initialValue: Money.editableAmount(entry?.unitPriceCents))
        _note = State(initialValue: entry?.note ?? "")
    }

    private var selectedItem: Consumable? {
        items.first { $0.id == selectedItemID }
    }

    private var parsedPriceCents: Int? {
        Money.cents(from: priceText)
    }

    private var invalidPrice: Bool {
        !priceText.trimmed.isEmpty && parsedPriceCents == nil
    }

    private var canSave: Bool {
        selectedItem != nil && !invalidPrice
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Item", selection: $selectedItemID) {
                        Text("Select item").tag(UUID?.none)
                        ForEach(items) { item in
                            Label(item.name, systemImage: item.category.systemImage)
                                .tag(Optional(item.id))
                        }
                    }
                    .onChange(of: selectedItemID) { _, newValue in
                        guard let item = items.first(where: { $0.id == newValue }) else { return }
                        priceText = Money.editableAmount(item.unitPriceCents)
                    }

                    if items.isEmpty {
                        Text("Add an item in the Items tab first.")
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    Stepper("Quantity: \(quantity)", value: $quantity, in: 1...999)
                    DatePicker("Date", selection: $timestamp, displayedComponents: .date)
                    Toggle("Include time", isOn: $hasTime)
                    if hasTime {
                        DatePicker("Time", selection: $timestamp, displayedComponents: .hourAndMinute)
                    }
                }

                Section {
                    HStack(spacing: 4) {
                        Text("Amount")
                        Spacer()
                        Text(Money.symbol(for: currencyCode))
                            .foregroundStyle(.secondary)
                        TextField("Optional", text: $priceText)
                            .monospacedDigit()
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 90)
                            #if os(iOS)
                            .keyboardType(.decimalPad)
                            #endif
                    }

                    if invalidPrice {
                        Text("Enter a valid price.")
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                } header: {
                    Text("Price per unit")
                } footer: {
                    Text("Leave empty to log without a price.")
                }

                Section("Note") {
                    TextField("Optional", text: $note, axis: .vertical)
                        .lineLimit(1...4)
                }

                if entry != nil {
                    Section {
                        Button("Delete entry", role: .destructive) {
                            confirmingDelete = true
                        }
                    }
                }
            }
            .navigationTitle(entry == nil ? "New entry" : "Edit entry")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                }
            }
            .alert("Delete entry?", isPresented: $confirmingDelete) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) { deleteEntry() }
            } message: {
                Text("This cannot be undone.")
            }
            #if os(macOS)
            .frame(minWidth: 480, minHeight: 560)
            #else
            .presentationDetents([.large])
            #endif
        }
    }

    private func save() {
        guard let selectedItem else { return }
        let normalizedDate = hasTime ? timestamp : timestamp.startOfDay()
        let price = priceText.trimmed.isEmpty ? nil : parsedPriceCents

        if let entry {
            entry.consumable = selectedItem
            entry.quantity = quantity
            entry.timestamp = normalizedDate
            entry.hasTime = hasTime
            entry.unitPriceCents = price
            entry.note = note.trimmed
        } else {
            let newEntry = ConsumptionEntry(
                consumable: selectedItem,
                quantity: quantity,
                timestamp: normalizedDate,
                hasTime: hasTime,
                unitPriceCents: price,
                note: note.trimmed
            )
            modelContext.insert(newEntry)
        }

        try? modelContext.save()
        dismiss()
    }

    private func deleteEntry() {
        guard let entry else { return }
        modelContext.delete(entry)
        try? modelContext.save()
        dismiss()
    }
}
