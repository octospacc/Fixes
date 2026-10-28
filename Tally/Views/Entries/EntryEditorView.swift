import SwiftUI
import SwiftData

struct EntryEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Consumable.sortOrder), SortDescriptor(\Consumable.name)])
    private var allItems: [Consumable]

    @AppStorage("currencyCode") private var currencyCode = Money.currencyCode()

    private let entry: ConsumptionEntry?

    @State private var selectedItemID: UUID?
    @State private var quantity: Int
    @State private var timestamp: Date
    @State private var hasTime: Bool
    @State private var tracksPrice: Bool
    @State private var priceText: String
    @State private var note: String
    @State private var confirmingDelete = false

    init(entry: ConsumptionEntry? = nil, initialItem: Consumable? = nil) {
        self.entry = entry
        let item = entry?.consumable ?? initialItem
        let price = entry?.unitPriceCents ?? initialItem?.unitPriceCents

        _selectedItemID = State(initialValue: item?.id)
        _quantity = State(initialValue: entry?.quantity ?? 1)
        _timestamp = State(initialValue: entry?.timestamp ?? .now)
        _hasTime = State(initialValue: entry?.hasTime ?? true)
        _tracksPrice = State(initialValue: price != nil)
        _priceText = State(initialValue: Money.editableAmount(price))
        _note = State(initialValue: entry?.note ?? "")
    }

    private var availableItems: [Consumable] {
        allItems.filter { $0.archivedAt == nil || $0.id == selectedItemID }
    }

    private var selectedItem: Consumable? {
        allItems.first { $0.id == selectedItemID }
    }

    private var parsedPriceCents: Int? {
        Money.cents(from: priceText)
    }

    private var hasInvalidPrice: Bool {
        tracksPrice && !priceText.trimmed.isEmpty && parsedPriceCents == nil
    }

    private var canSave: Bool {
        guard selectedItem != nil else { return false }
        if tracksPrice && parsedPriceCents == nil { return false }
        return true
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    itemSection
                    quantityAndTimeSection
                    priceSection
                    noteSection
                    if entry != nil {
                        deleteSection
                    }
                }
                .padding(20)
                .frame(maxWidth: 620)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(TallyBackground())
            .navigationTitle(entry == nil ? "Log an entry" : "Edit entry")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(TallyTheme.muted)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                }
            }
            .alert("Delete this entry?", isPresented: $confirmingDelete) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) { deleteEntry() }
            } message: {
                Text("This can't be undone.")
            }
            #if os(macOS)
            .frame(minWidth: 560, minHeight: 690)
            #else
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            #endif
        }
    }

    private var itemSection: some View {
        editorCard(title: "What did you count?", symbolName: "square.grid.2x2") {
            if availableItems.isEmpty {
                Text("Add an item from the Items tab first.")
                    .font(TallyTheme.bodyFont)
                    .foregroundStyle(TallyTheme.muted)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(availableItems, id: \.id) { item in
                            itemButton(item)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .scrollClipDisabled()
            }
        }
    }

    private func itemButton(_ item: Consumable) -> some View {
        let selected = item.id == selectedItemID
        return Button {
            withAnimation(.easeOut(duration: 0.16)) {
                selectedItemID = item.id
                let defaultPrice = item.unitPriceCents
                tracksPrice = defaultPrice != nil
                priceText = Money.editableAmount(defaultPrice)
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: item.symbolName)
                    .font(.system(size: 13, weight: .semibold))
                Text(item.name)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .lineLimit(1)
            }
            .foregroundStyle(selected ? TallyTheme.surface : TallyTheme.ink)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(
                Capsule().fill(selected ? AnyShapeStyle(TallyTheme.ink) : AnyShapeStyle(TallyTheme.canvas))
            )
            .overlay(
                Capsule().strokeBorder(
                    selected ? item.color.opacity(0.9) : TallyTheme.hairline,
                    lineWidth: selected ? 1.5 : 1
                )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.name)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private var quantityAndTimeSection: some View {
        editorCard(title: "Quantity & time", symbolName: "calendar") {
            HStack {
                Text("Quantity")
                    .font(TallyTheme.bodyFont)
                    .foregroundStyle(TallyTheme.ink)
                Spacer()
                HStack(spacing: 12) {
                    Button {
                        if quantity > 1 { quantity -= 1 }
                    } label: {
                        Image(systemName: "minus")
                    }
                    .buttonStyle(QuantityButtonStyle(enabled: quantity > 1))

                    Text("\(quantity)")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .frame(minWidth: 26)
                        .foregroundStyle(TallyTheme.ink)

                    Button {
                        if quantity < 999 { quantity += 1 }
                    } label: {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(QuantityButtonStyle(enabled: true))
                }
            }

            Divider().overlay(TallyTheme.hairline)

            VStack(spacing: 10) {
                HStack {
                    Text("When")
                        .font(TallyTheme.bodyFont)
                        .foregroundStyle(TallyTheme.ink)
                    Spacer()
                    Button {
                        timestamp = .now
                        hasTime = true
                    } label: {
                        Label("Now", systemImage: "arrow.counterclockwise")
                            .labelStyle(.titleAndIcon)
                    }
                    .buttonStyle(SoftButtonStyle())
                }

                Toggle(isOn: $hasTime.animation(.easeOut(duration: 0.16))) {
                    Text("Include a time")
                        .font(TallyTheme.bodyFont)
                        .foregroundStyle(TallyTheme.ink)
                }
                .tint(TallyTheme.accent)

                #if os(macOS)
                DatePicker("Date", selection: $timestamp, displayedComponents: .date)
                    .datePickerStyle(.field)
                    .font(TallyTheme.bodyFont)
                if hasTime {
                    DatePicker("Time", selection: $timestamp, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.field)
                        .font(TallyTheme.bodyFont)
                }
                #else
                DatePicker("Date", selection: $timestamp, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .font(TallyTheme.bodyFont)
                if hasTime {
                    DatePicker("Time", selection: $timestamp, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.compact)
                        .font(TallyTheme.bodyFont)
                }
                #endif

                if !hasTime {
                    Text("Time is optional. This entry is counted for the day, without a specific hour.")
                        .font(TallyTheme.captionFont)
                        .foregroundStyle(TallyTheme.muted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private var priceSection: some View {
        editorCard(title: "Price", symbolName: "tag") {
            Toggle(isOn: $tracksPrice.animation(.easeOut(duration: 0.16))) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Track a price")
                        .font(TallyTheme.bodyFont)
                        .foregroundStyle(TallyTheme.ink)
                    Text("Optional. One price per unit.")
                        .font(TallyTheme.captionFont)
                        .foregroundStyle(TallyTheme.muted)
                }
            }
            .tint(TallyTheme.accent)

            if tracksPrice {
                HStack(spacing: 8) {
                    Text(Money.symbol(for: currencyCode))
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(TallyTheme.muted)
                    TextField("0.00", text: $priceText)
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                        .foregroundStyle(TallyTheme.ink)
                        .textFieldStyle(.plain)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(
                    RoundedRectangle(cornerRadius: TallyTheme.controlRadius, style: .continuous)
                        .fill(TallyTheme.canvas)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: TallyTheme.controlRadius, style: .continuous)
                        .strokeBorder(hasInvalidPrice ? Color.red.opacity(0.7) : TallyTheme.hairline, lineWidth: 1)
                )

                if hasInvalidPrice {
                    Text("Enter a valid amount, like 2.50.")
                        .font(TallyTheme.captionFont)
                        .foregroundStyle(.red)
                } else if priceText.trimmed.isEmpty {
                    Text("Enter an amount, or turn off Track a price.")
                        .font(TallyTheme.captionFont)
                        .foregroundStyle(TallyTheme.muted)
                } else if let cents = parsedPriceCents {
                    HStack {
                        Text("Entry total")
                            .font(TallyTheme.captionFont)
                            .foregroundStyle(TallyTheme.muted)
                        Spacer()
                        PriceText(cents: cents * quantity, currencyCode: currencyCode, emphasized: true)
                    }
                }
            }
        }
    }

    private var noteSection: some View {
        editorCard(title: "Note", symbolName: "text.alignleft") {
            TextField("Optional note", text: $note, axis: .vertical)
                .font(TallyTheme.bodyFont)
                .lineLimit(2...4)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: TallyTheme.controlRadius, style: .continuous)
                        .fill(TallyTheme.canvas)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: TallyTheme.controlRadius, style: .continuous)
                        .strokeBorder(TallyTheme.hairline, lineWidth: 1)
                )
        }
    }

    private var deleteSection: some View {
        Button(role: .destructive) {
            confirmingDelete = true
        } label: {
            HStack {
                Image(systemName: "trash")
                Text("Delete entry")
                Spacer()
            }
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .foregroundStyle(Color.red.opacity(0.85))
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(TallyTheme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color.red.opacity(0.12), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .padding(.top, 2)
    }

    private func editorCard<Content: View>(
        title: String,
        symbolName: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 13) {
            Label(title, systemImage: symbolName)
                .font(TallyTheme.sectionFont)
                .foregroundStyle(TallyTheme.ink)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .tallyCard(padding: 16)
    }

    private func save() {
        guard let selectedItem else { return }
        let normalizedDate = hasTime ? timestamp : timestamp.startOfDay()
        let price = tracksPrice ? parsedPriceCents : nil

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

private struct QuantityButtonStyle: ButtonStyle {
    let enabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(enabled ? TallyTheme.ink : TallyTheme.muted.opacity(0.35))
            .frame(width: 30, height: 30)
            .background(Circle().fill(TallyTheme.canvas))
            .overlay(Circle().strokeBorder(TallyTheme.hairline, lineWidth: 1))
            .scaleEffect(configuration.isPressed && enabled ? 0.9 : 1)
    }
}
