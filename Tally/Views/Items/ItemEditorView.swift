import SwiftUI
import SwiftData

struct ItemEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: [SortDescriptor(\Consumable.sortOrder), SortDescriptor(\Consumable.name)])
    private var allItems: [Consumable]

    @AppStorage("currencyCode") private var currencyCode = Money.currencyCode()

    private let item: Consumable?

    @State private var name: String
    @State private var symbolName: String
    @State private var colorHex: String
    @State private var category: ConsumableCategory
    @State private var tracksPrice: Bool
    @State private var priceText: String
    @State private var confirmingDelete = false

    private let symbolChoices = [
        "cup.and.saucer.fill", "mug.fill", "takeoutbag.and.cup.and.straw.fill",
        "fork.knife", "birthday.cake.fill", "carrot.fill", "popcorn.fill",
        "ticket.fill", "dice.fill", "gamecontroller.fill", "tv.fill",
        "smoke.fill", "flame.fill", "drop.fill", "waterbottle.fill",
        "pill.fill", "leaf.fill", "figure.run", "cart.fill", "bag.fill",
        "shippingbox.fill", "creditcard.fill", "music.note", "wineglass.fill"
    ]

    private let colorChoices = [
        "B65B43", "C7973A", "A77443", "667B5D", "5D8A86",
        "5A739A", "826AA6", "C26A72", "7A7C74", "8C654C"
    ]

    init(item: Consumable? = nil) {
        self.item = item
        _name = State(initialValue: item?.name ?? "")
        _symbolName = State(initialValue: item?.symbolName ?? "cup.and.saucer.fill")
        _colorHex = State(initialValue: item?.colorHex ?? "B65B43")
        _category = State(initialValue: item?.category ?? .drinks)
        _tracksPrice = State(initialValue: item?.unitPriceCents != nil)
        _priceText = State(initialValue: Money.editableAmount(item?.unitPriceCents))
    }

    private var previewName: String {
        name.trimmed.isEmpty ? "New item" : name.trimmed
    }

    private var parsedPriceCents: Int? {
        Money.cents(from: priceText)
    }

    private var duplicateName: Bool {
        let candidate = name.trimmed.lowercased()
        guard !candidate.isEmpty else { return false }
        return allItems.contains { other in
            other.id != item?.id && other.normalizedName == candidate
        }
    }

    private var invalidPrice: Bool {
        tracksPrice && !priceText.trimmed.isEmpty && parsedPriceCents == nil
    }

    private var canSave: Bool {
        guard !name.trimmed.isEmpty, !duplicateName else { return false }
        if tracksPrice && parsedPriceCents == nil { return false }
        return true
    }

    private var unusedSuggestions: [ConsumablePreset] {
        let usedNames = Set(allItems.map(\.normalizedName))
        return ConsumablePreset.allSuggestions.filter { !usedNames.contains($0.name.lowercased()) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    preview
                    if item == nil, !unusedSuggestions.isEmpty {
                        suggestionsSection
                    }
                    detailsSection
                    appearanceSection
                    priceSection
                    if let item {
                        managementSection(item)
                    }
                }
                .padding(20)
                .frame(maxWidth: 620)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(TallyBackground())
            .navigationTitle(item == nil ? "New item" : "Edit item")
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
            .alert("Delete this item?", isPresented: $confirmingDelete) {
                Button("Cancel", role: .cancel) {}
                Button("Delete item and entries", role: .destructive) { deleteItem() }
            } message: {
                Text("This also deletes every entry logged for this item. To keep the history, archive it instead.")
            }
            #if os(macOS)
            .frame(minWidth: 580, minHeight: 750)
            #else
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            #endif
        }
    }

    private var preview: some View {
        VStack(spacing: 10) {
            ItemIcon(symbolName: symbolName, tint: Color(hex: colorHex), size: 70)
            Text(previewName)
                .font(.system(size: 23, weight: .semibold, design: .serif))
                .foregroundStyle(TallyTheme.ink)
                .lineLimit(1)
            Text(category.title.uppercased())
                .font(TallyTheme.overlineFont)
                .tracking(1)
                .foregroundStyle(TallyTheme.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: TallyTheme.cardRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [TallyTheme.surface, Color(hex: colorHex).opacity(0.06)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: TallyTheme.cardRadius, style: .continuous)
                .strokeBorder(TallyTheme.hairline.opacity(0.85), lineWidth: 1)
        )
    }

    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: 11) {
            Label("Start from a suggestion", systemImage: "sparkles")
                .font(TallyTheme.sectionFont)
                .foregroundStyle(TallyTheme.ink)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(unusedSuggestions) { preset in
                        Button {
                            apply(preset)
                        } label: {
                            HStack(spacing: 7) {
                                Image(systemName: preset.symbolName)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(Color(hex: preset.colorHex))
                                Text(preset.name)
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundStyle(TallyTheme.ink)
                            }
                            .padding(.horizontal, 11)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(TallyTheme.canvas))
                            .overlay(Capsule().strokeBorder(TallyTheme.hairline, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 1)
            }
            .scrollClipDisabled()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .tallyCard(padding: 16)
    }

    private var detailsSection: some View {
        editorCard(title: "Details", symbolName: "tag") {
            VStack(alignment: .leading, spacing: 6) {
                Text("Name")
                    .font(TallyTheme.captionFont)
                    .foregroundStyle(TallyTheme.muted)
                TextField("e.g. Coffee", text: $name)
                    .font(TallyTheme.bodyFont)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 11)
                    .background(fieldBackground)
                    .overlay(fieldBorder)
            }

            if duplicateName {
                Text("An item with this name already exists.")
                    .font(TallyTheme.captionFont)
                    .foregroundStyle(.red)
            }

            HStack {
                Text("Category")
                    .font(TallyTheme.bodyFont)
                    .foregroundStyle(TallyTheme.ink)
                Spacer()
                Picker("Category", selection: $category) {
                    ForEach(ConsumableCategory.allCases) { category in
                        Label(category.title, systemImage: category.symbolName)
                            .tag(category)
                    }
                }
                .pickerStyle(.menu)
                .tint(TallyTheme.accent)
            }
        }
    }

    private var appearanceSection: some View {
        editorCard(title: "Appearance", symbolName: "paintpalette") {
            VStack(alignment: .leading, spacing: 6) {
                Text("Icon")
                    .font(TallyTheme.captionFont)
                    .foregroundStyle(TallyTheme.muted)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 38, maximum: 44), spacing: 8)], spacing: 8) {
                    ForEach(symbolChoices, id: \.self) { symbol in
                        Button {
                            symbolName = symbol
                        } label: {
                            Image(systemName: symbol)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(symbol == symbolName ? Color.white : TallyTheme.ink)
                                .frame(width: 40, height: 40)
                                .background(
                                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                                        .fill(symbol == symbolName ? AnyShapeStyle(TallyTheme.accentGradient) : AnyShapeStyle(TallyTheme.canvas))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                                        .strokeBorder(symbol == symbolName ? Color.clear : TallyTheme.hairline, lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(symbol)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Color")
                    .font(TallyTheme.captionFont)
                    .foregroundStyle(TallyTheme.muted)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 30, maximum: 34), spacing: 10)], spacing: 10) {
                    ForEach(colorChoices, id: \.self) { hex in
                        Button {
                            colorHex = hex
                        } label: {
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 29, height: 29)
                                .overlay(
                                    Circle()
                                        .strokeBorder(Color.white.opacity(colorHex == hex ? 0.95 : 0), lineWidth: 2)
                                        .padding(2)
                                )
                                .overlay(
                                    Circle()
                                        .strokeBorder(Color(hex: hex), lineWidth: colorHex == hex ? 2 : 0)
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Color \(hex)")
                        .accessibilityAddTraits(colorHex == hex ? .isSelected : [])
                    }
                }
            }
        }
    }

    private var priceSection: some View {
        editorCard(title: "Price", symbolName: "creditcard") {
            Toggle(isOn: $tracksPrice.animation(.easeOut(duration: 0.16))) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Default price")
                        .font(TallyTheme.bodyFont)
                        .foregroundStyle(TallyTheme.ink)
                    Text("Optional. Applied to new entries; you can change it per entry.")
                        .font(TallyTheme.captionFont)
                        .foregroundStyle(TallyTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
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
                        .textFieldStyle(.plain)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(fieldBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: TallyTheme.controlRadius, style: .continuous)
                        .strokeBorder(invalidPrice ? Color.red.opacity(0.7) : TallyTheme.hairline, lineWidth: 1)
                )

                if invalidPrice {
                    Text("Enter a valid amount, like 2.50.")
                        .font(TallyTheme.captionFont)
                        .foregroundStyle(.red)
                } else if priceText.trimmed.isEmpty {
                    Text("Enter an amount, or turn off Default price.")
                        .font(TallyTheme.captionFont)
                        .foregroundStyle(TallyTheme.muted)
                }
            }
        }
    }

    private func managementSection(_ item: Consumable) -> some View {
        VStack(spacing: 0) {
            Button {
                if item.isArchived {
                    item.restore()
                } else {
                    item.archive()
                }
                try? modelContext.save()
                dismiss()
            } label: {
                HStack {
                    Image(systemName: item.isArchived ? "arrow.uturn.backward.circle" : "archivebox")
                    Text(item.isArchived ? "Restore item" : "Archive item")
                    Spacer()
                }
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(TallyTheme.ink)
                .padding(16)
            }
            .buttonStyle(.plain)

            Divider().overlay(TallyTheme.hairline)

            Button(role: .destructive) {
                confirmingDelete = true
            } label: {
                HStack {
                    Image(systemName: "trash")
                    Text("Delete item and entries")
                    Spacer()
                }
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.red.opacity(0.85))
                .padding(16)
            }
            .buttonStyle(.plain)
        }
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(TallyTheme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(TallyTheme.hairline.opacity(0.85), lineWidth: 1)
        )
        .padding(.top, 2)
    }

    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: TallyTheme.controlRadius, style: .continuous)
            .fill(TallyTheme.canvas)
    }

    private var fieldBorder: some View {
        RoundedRectangle(cornerRadius: TallyTheme.controlRadius, style: .continuous)
            .strokeBorder(TallyTheme.hairline, lineWidth: 1)
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

    private func apply(_ preset: ConsumablePreset) {
        name = preset.name
        symbolName = preset.symbolName
        colorHex = preset.colorHex
        category = preset.category
        if let price = preset.suggestedPriceCents {
            tracksPrice = true
            priceText = Money.editableAmount(price)
        }
    }

    private func save() {
        guard canSave else { return }
        let price = tracksPrice ? parsedPriceCents : nil
        let cleanName = name.trimmed

        if let item {
            item.name = cleanName
            item.symbolName = symbolName
            item.colorHex = colorHex
            item.category = category
            item.unitPriceCents = price
        } else {
            let nextOrder = (allItems.map(\.sortOrder).max() ?? -1) + 1
            let newItem = Consumable(
                name: cleanName,
                symbolName: symbolName,
                colorHex: colorHex,
                category: category,
                unitPriceCents: price,
                sortOrder: nextOrder
            )
            modelContext.insert(newItem)
        }
        try? modelContext.save()
        dismiss()
    }

    private func deleteItem() {
        guard let item else { return }
        modelContext.delete(item)
        try? modelContext.save()
        dismiss()
    }
}
