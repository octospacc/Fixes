import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.calendar) private var calendar

    @Query(sort: [SortDescriptor(\ConsumptionEntry.timestamp, order: .reverse)])
    private var entries: [ConsumptionEntry]

    @Query(sort: [SortDescriptor(\Consumable.sortOrder), SortDescriptor(\Consumable.name)])
    private var items: [Consumable]

    @AppStorage("currencyCode") private var currencyCode = Money.currencyCode()

    @State private var searchText = ""
    @State private var selectedItemID: UUID?
    @State private var editorRoute: EntryEditorRoute?
    @State private var entryPendingDeletion: ConsumptionEntry?

    private var filteredEntries: [ConsumptionEntry] {
        let query = searchText.trimmed.lowercased()
        return entries.filter { entry in
            let matchesItem = selectedItemID == nil || entry.consumable?.id == selectedItemID
            guard matchesItem else { return false }
            guard !query.isEmpty else { return true }
            return entry.itemName.lowercased().contains(query)
                || entry.note.lowercased().contains(query)
                || entry.category.title.lowercased().contains(query)
        }
    }

    private var selectedItem: Consumable? {
        guard let selectedItemID else { return nil }
        return items.first { $0.id == selectedItemID }
    }

    private var filteredQuantity: Int {
        filteredEntries.reduce(0) { $0 + $1.quantity }
    }

    private var filteredSpendCents: Int? {
        let priced = filteredEntries.filter { $0.unitPriceCents != nil }
        guard !priced.isEmpty else { return nil }
        return priced.compactMap(\.totalSpendCents).reduce(0, +)
    }

    private var dayGroups: [HistoryDay] {
        let grouped = Dictionary(grouping: filteredEntries) {
            calendar.startOfDay(for: $0.timestamp)
        }
        return grouped.map { day, dayEntries in
            HistoryDay(
                day: day,
                entries: dayEntries.sorted { $0.timestamp > $1.timestamp }
            )
        }
        .sorted { $0.day > $1.day }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                summary

                if let selectedItem {
                    HStack(spacing: 10) {
                        ChipLabel(title: selectedItem.name, symbolName: selectedItem.symbolName, selected: true)
                        Button("Clear filter") {
                            withAnimation(.easeOut(duration: 0.16)) { selectedItemID = nil }
                        }
                        .font(TallyTheme.captionFont)
                        .foregroundStyle(TallyTheme.accent)
                        .buttonStyle(.plain)
                        Spacer()
                    }
                }

                if dayGroups.isEmpty {
                    TallyEmptyState(
                        symbol: entries.isEmpty ? "clock.arrow.circlepath" : "magnifyingglass",
                        title: entries.isEmpty ? "No history yet" : "Nothing matches",
                        message: entries.isEmpty
                            ? "Every entry you log will appear here, grouped by day."
                            : "Try a different search or clear the item filter.",
                        actionTitle: entries.isEmpty ? "Log an entry" : "Clear filters",
                        action: {
                            if entries.isEmpty {
                                editorRoute = .add
                            } else {
                                searchText = ""
                                selectedItemID = nil
                            }
                        }
                    )
                    .frame(maxWidth: .infinity)
                    .tallyCard(padding: 4)
                } else {
                    ForEach(dayGroups) { group in
                        dayCard(group)
                    }
                }
            }
            .padding(.horizontal, TallyTheme.pagePadding)
            .padding(.top, 6)
            .padding(.bottom, 40)
            .tallyPageWidth()
        }
        .background(TallyBackground())
        .navigationTitle("History")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(TallyTheme.canvas, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        #endif
        .searchable(text: $searchText, prompt: "Search items and notes")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                filterMenu
                Button {
                    editorRoute = .add
                } label: {
                    Label("Log", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .tint(TallyTheme.accent)
                .keyboardShortcut("n", modifiers: .command)
                .accessibilityLabel("Log an entry")
            }
        }
        .sheet(item: $editorRoute) { route in
            switch route {
            case .add:
                EntryEditorView()
            case .edit(let entry):
                EntryEditorView(entry: entry)
            }
        }
        .alert("Delete entry?", isPresented: deleteAlertBinding, presenting: entryPendingDeletion) { entry in
            Button("Cancel", role: .cancel) { entryPendingDeletion = nil }
            Button("Delete", role: .destructive) { delete(entry) }
        } message: { entry in
            Text("Delete this \(entry.itemName.lowercased()) entry? This can't be undone.")
        }
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("THE LEDGER")
                .font(TallyTheme.overlineFont)
                .tracking(1.2)
                .foregroundStyle(TallyTheme.muted)

            HStack(spacing: 0) {
                historyMetric(value: "\(filteredEntries.count)", label: "entries")
                summaryDivider
                historyMetric(value: "\(filteredQuantity)", label: "items")
                summaryDivider
                historyMetric(value: Money.display(filteredSpendCents, currencyCode: currencyCode), label: "spent")
            }
            .padding(.vertical, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .tallyCard(padding: 16)
    }

    private var summaryDivider: some View {
        Rectangle()
            .fill(TallyTheme.hairline)
            .frame(width: 1, height: 34)
            .padding(.horizontal, 16)
    }

    private func historyMetric(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value)
                .font(.system(size: 19, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(TallyTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(label)
                .font(TallyTheme.captionFont)
                .foregroundStyle(TallyTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var filterMenu: some View {
        Menu {
            Button {
                selectedItemID = nil
            } label: {
                if selectedItemID == nil {
                    Label("All items", systemImage: "checkmark")
                } else {
                    Text("All items")
                }
            }

            if !items.isEmpty {
                Divider()
                ForEach(items, id: \.id) { item in
                    Button {
                        selectedItemID = item.id
                    } label: {
                        if selectedItemID == item.id {
                            Label(item.name, systemImage: "checkmark")
                        } else {
                            Text(item.name)
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle")
        }
        .accessibilityLabel("Filter history")
    }

    private func dayCard(_ group: HistoryDay) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text(TallyDateFormat.historyHeader(group.day, calendar: calendar))
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(TallyTheme.ink)
                Spacer()
                Text("\(group.quantity) \(group.quantity == 1 ? "item" : "items")")
                    .font(TallyTheme.captionFont)
                    .foregroundStyle(TallyTheme.muted)
                if let spend = group.spendCents {
                    Text("·")
                        .font(TallyTheme.captionFont)
                        .foregroundStyle(TallyTheme.muted.opacity(0.5))
                    Text(Money.display(spend, currencyCode: currencyCode))
                        .font(TallyTheme.captionFont)
                        .monospacedDigit()
                        .foregroundStyle(TallyTheme.muted)
                }
            }
            .padding(.horizontal, 15)
            .padding(.top, 14)
            .padding(.bottom, 10)

            Divider()
                .overlay(TallyTheme.hairline.opacity(0.7))

            ForEach(Array(group.entries.enumerated()), id: \.element.id) { index, entry in
                EntryRow(
                    entry: entry,
                    currencyCode: currencyCode,
                    onEdit: { editorRoute = .edit(entry) },
                    onDelete: { entryPendingDeletion = entry }
                )
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .contentShape(Rectangle())
                .onTapGesture { editorRoute = .edit(entry) }

                if index < group.entries.count - 1 {
                    Divider()
                        .overlay(TallyTheme.hairline.opacity(0.7))
                        .padding(.leading, 66)
                }
            }
            .padding(.vertical, 4)
        }
        .background(
            RoundedRectangle(cornerRadius: TallyTheme.cardRadius, style: .continuous)
                .fill(TallyTheme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: TallyTheme.cardRadius, style: .continuous)
                .strokeBorder(TallyTheme.hairline.opacity(0.85), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 14, x: 0, y: 7)
    }

    private var deleteAlertBinding: Binding<Bool> {
        Binding(
            get: { entryPendingDeletion != nil },
            set: { if !$0 { entryPendingDeletion = nil } }
        )
    }

    private func delete(_ entry: ConsumptionEntry) {
        modelContext.delete(entry)
        try? modelContext.save()
        entryPendingDeletion = nil
    }
}

private struct HistoryDay: Identifiable {
    let day: Date
    let entries: [ConsumptionEntry]

    var id: Date { day }

    var quantity: Int {
        entries.reduce(0) { $0 + $1.quantity }
    }

    var spendCents: Int? {
        let priced = entries.filter { $0.unitPriceCents != nil }
        guard !priced.isEmpty else { return nil }
        return priced.compactMap(\.totalSpendCents).reduce(0, +)
    }
}

private enum EntryEditorRoute: Identifiable {
    case add
    case edit(ConsumptionEntry)

    var id: String {
        switch self {
        case .add: "add"
        case .edit(let entry): "edit-\(entry.id.uuidString)"
        }
    }
}
