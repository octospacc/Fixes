import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.calendar) private var calendar

    @Query(sort: [SortDescriptor(\ConsumptionEntry.timestamp, order: .reverse)])
    private var entries: [ConsumptionEntry]

    @AppStorage("currencyCode") private var currencyCode = Money.currencyCode()

    @State private var searchText = ""
    @State private var editorRoute: EntryEditorRoute?
    @State private var entryPendingDeletion: ConsumptionEntry?

    private var filteredEntries: [ConsumptionEntry] {
        let query = searchText.trimmed.lowercased()
        guard !query.isEmpty else { return entries }
        return entries.filter {
            $0.itemName.lowercased().contains(query)
                || $0.note.lowercased().contains(query)
        }
    }

    private var dayGroups: [HistoryDay] {
        let grouped = Dictionary(grouping: filteredEntries) {
            calendar.startOfDay(for: $0.timestamp)
        }
        return grouped.map { day, entries in
            HistoryDay(
                day: day,
                entries: entries.sorted { $0.timestamp > $1.timestamp }
            )
        }
        .sorted { $0.day > $1.day }
    }

    var body: some View {
        Group {
            if entries.isEmpty {
                ContentUnavailableView(
                    "No entries",
                    systemImage: "clock",
                    description: Text("Entries you add will appear here.")
                )
            } else if filteredEntries.isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else {
                List {
                    ForEach(dayGroups) { group in
                        Section(TallyDateFormat.historyHeader(group.day, calendar: calendar)) {
                            ForEach(group.entries) { entry in
                                Button {
                                    editorRoute = .edit(entry)
                                } label: {
                                    EntryRow(entry: entry, currencyCode: currencyCode)
                                }
                                .buttonStyle(.plain)
                                .swipeActions(edge: .trailing) {
                                    Button("Delete", role: .destructive) {
                                        entryPendingDeletion = entry
                                    }
                                }
                                .contextMenu {
                                    Button("Edit") { editorRoute = .edit(entry) }
                                    Button("Delete", role: .destructive) {
                                        entryPendingDeletion = entry
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("History")
        #if os(iOS)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search entries")
        #else
        .searchable(text: $searchText, prompt: "Search entries")
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    editorRoute = .add
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add entry")
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
            Text("Delete this \(entry.itemName) entry?")
        }
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
