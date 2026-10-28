import SwiftUI
import SwiftData

struct ItemEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: [SortDescriptor(\Consumable.name)])
    private var items: [Consumable]

    @AppStorage("currencyCode") private var currencyCode = Money.currencyCode()

    private let item: Consumable?

    @State private var name: String
    @State private var category: ConsumableCategory
    @State private var priceText: String

    init(item: Consumable? = nil) {
        self.item = item
        _name = State(initialValue: item?.name ?? "")
        _category = State(initialValue: item?.category ?? .other)
        _priceText = State(initialValue: Money.editableAmount(item?.unitPriceCents))
    }

    private var parsedPriceCents: Int? {
        Money.cents(from: priceText)
    }

    private var invalidPrice: Bool {
        !priceText.trimmed.isEmpty && parsedPriceCents == nil
    }

    private var duplicateName: Bool {
        let candidate = name.trimmed.lowercased()
        guard !candidate.isEmpty else { return false }
        return items.contains {
            $0.id != item?.id && $0.normalizedName == candidate
        }
    }

    private var canSave: Bool {
        !name.trimmed.isEmpty && !duplicateName && !invalidPrice
    }

    private var suggestions: [ConsumablePreset] {
        let existingNames = Set(items.map(\.normalizedName))
        return ConsumablePreset.allSuggestions.filter {
            !existingNames.contains($0.name.lowercased())
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)

                    Picker("Category", selection: $category) {
                        ForEach(ConsumableCategory.allCases) { category in
                            Text(category.title)
                                .tag(category)
                        }
                    }

                    HStack(spacing: 4) {
                        Text("Default price")
                        Spacer()
                        Text(Money.symbol(for: currencyCode))
                            .foregroundStyle(.secondary)
                        TextField("None", text: $priceText)
                            .monospacedDigit()
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 90)
                            #if os(iOS)
                            .keyboardType(.decimalPad)
                            #endif
                    }

                    if duplicateName {
                        Text("An item with this name already exists.")
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }

                    if invalidPrice {
                        Text("Enter a valid price.")
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                } footer: {
                    Text("The default price is used for new entries. Leave it empty for no price.")
                }

                if item == nil, !suggestions.isEmpty {
                    Section("Starter items") {
                        Menu {
                            ForEach(suggestions) { preset in
                                Button(preset.name) {
                                    name = preset.name
                                    category = preset.category
                                }
                            }
                        } label: {
                            HStack {
                                Text("Use a suggestion")
                                Spacer()
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle(item == nil ? "New item" : "Edit item")
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
            #if os(macOS)
            .frame(minWidth: 460, minHeight: 460)
            #else
            .presentationDetents([.large])
            #endif
        }
    }

    private func save() {
        guard canSave else { return }
        let cleanName = name.trimmed
        let price = priceText.trimmed.isEmpty ? nil : parsedPriceCents

        if let item {
            item.name = cleanName
            item.category = category
            item.unitPriceCents = price
        } else {
            let newItem = Consumable(
                name: cleanName,
                category: category,
                unitPriceCents: price
            )
            modelContext.insert(newItem)
        }

        try? modelContext.save()
        dismiss()
    }
}
