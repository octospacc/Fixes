import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.calendar) private var calendar

    @Query(sort: [SortDescriptor(\Consumable.createdAt)])
    private var items: [Consumable]

    @Query(sort: [SortDescriptor(\ConsumptionEntry.timestamp, order: .reverse)])
    private var entries: [ConsumptionEntry]

    @AppStorage("currencyCode") private var currencyCode = Money.currencyCode()

    var onAddItems: () -> Void = {}

    @State private var editorRoute: EntryEditorRoute?
    @State private var entryPendingDeletion: ConsumptionEntry?
    @State private var feedbackTrigger = 0

    private var todayEntries: [ConsumptionEntry] {
        entries.filter { calendar.isDateInToday($0.timestamp) }
    }

    private var totalQuantity: Int {
        todayEntries.reduce(0) { $0 + $1.quantity }
    }

    private var pricedEntries: [ConsumptionEntry] {
        todayEntries.filter { $0.unitPriceCents != nil }
    }

    private var totalSpendCents: Int? {
        guard !pricedEntries.isEmpty else { return nil }
        return pricedEntries.compactMap(\.totalSpendCents).reduce(0, +)
    }

    var body: some View {
        List {
            Section("Quick add") {
                if items.isEmpty {
                    HStack {
                        Text("No items yet.")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Add items", action: onAddItems)
                    }
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(items) { item in
                                Button {
                                    add(item)
                                } label: {
                                    Label(item.name, systemImage: item.category.systemImage)
                                }
                                .buttonStyle(.bordered)
                            }

                        }
                        .padding(.vertical, 2)
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
            }

            Section {
                LabeledContent("Items", value: "\(totalQuantity)")
                LabeledContent("Spent") {
                    Text(Money.display(totalSpendCents, currencyCode: currencyCode))
                }
            }

            Section("Today's entries") {
                if todayEntries.isEmpty {
                    Text("No entries today.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(todayEntries) { entry in
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
        .navigationTitle("Today")
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
        .sensoryFeedback(.success, trigger: feedbackTrigger)
        #if DEBUG
        .onAppear {
            if ProcessInfo.processInfo.arguments.contains("-openAddEntry"), editorRoute == nil {
                editorRoute = .add
            }
        }
        #endif
    }

    private var deleteAlertBinding: Binding<Bool> {
        Binding(
            get: { entryPendingDeletion != nil },
            set: { if !$0 { entryPendingDeletion = nil } }
        )
    }

    private func add(_ item: Consumable) {
        let entry = ConsumptionEntry(
            consumable: item,
            quantity: 1,
            timestamp: .now,
            hasTime: true,
            unitPriceCents: item.unitPriceCents
        )
        modelContext.insert(entry)
        try? modelContext.save()
        feedbackTrigger += 1
    }

    private func delete(_ entry: ConsumptionEntry) {
        modelContext.delete(entry)
        try? modelContext.save()
        entryPendingDeletion = nil
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
