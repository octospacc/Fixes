import SwiftUI
import SwiftData

struct ItemsView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: [SortDescriptor(\Consumable.createdAt)])
    private var items: [Consumable]

    @Query private var entries: [ConsumptionEntry]

    @AppStorage("currencyCode") private var currencyCode = Money.currencyCode()

    @State private var editorRoute: ItemEditorRoute?
    @State private var itemPendingDeletion: Consumable?

    var body: some View {
        Group {
            if items.isEmpty {
                ContentUnavailableView {
                    Label("No items", systemImage: "list.bullet")
                } description: {
                    Text("Add items to start tracking.")
                } actions: {
                    Button("Add starter items") {
                        StarterItems.add(to: modelContext)
                    }
                    Button("New item") {
                        editorRoute = .add
                    }
                }
            } else {
                List {
                    Section {
                        ForEach(items) { item in
                            Button {
                                editorRoute = .edit(item)
                            } label: {
                                itemRow(item)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .swipeActions(edge: .trailing) {
                                Button("Delete", role: .destructive) {
                                    itemPendingDeletion = item
                                }
                            }
                            .contextMenu {
                                Button("Edit") { editorRoute = .edit(item) }
                                Button("Delete", role: .destructive) {
                                    itemPendingDeletion = item
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Items")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    editorRoute = .add
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("New item")
            }
        }
        .sheet(item: $editorRoute) { route in
            switch route {
            case .add:
                ItemEditorView()
            case .edit(let item):
                ItemEditorView(item: item)
            }
        }
        .alert("Delete item?", isPresented: deleteAlertBinding, presenting: itemPendingDeletion) { item in
            Button("Cancel", role: .cancel) { itemPendingDeletion = nil }
            Button("Delete", role: .destructive) { delete(item) }
        } message: { item in
            Text("This will also delete all entries for \(item.name).")
        }
        #if DEBUG
        .onAppear {
            if ProcessInfo.processInfo.arguments.contains("-openNewItem"), editorRoute == nil {
                editorRoute = .add
            }
        }
        #endif
    }

    private func itemRow(_ item: Consumable) -> some View {
        HStack(spacing: 12) {
            Image(systemName: item.category.systemImage)
                .foregroundStyle(.secondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                Text(item.category.title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let price = item.unitPriceCents {
                Text(Money.display(price, currencyCode: currencyCode))
                    .font(.subheadline)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var deleteAlertBinding: Binding<Bool> {
        Binding(
            get: { itemPendingDeletion != nil },
            set: { if !$0 { itemPendingDeletion = nil } }
        )
    }

    private func delete(_ item: Consumable) {
        for entry in entries where entry.consumable?.id == item.id {
            modelContext.delete(entry)
        }
        modelContext.delete(item)
        try? modelContext.save()
        itemPendingDeletion = nil
    }
}

private enum ItemEditorRoute: Identifiable {
    case add
    case edit(Consumable)

    var id: String {
        switch self {
        case .add: "add"
        case .edit(let item): "edit-\(item.id.uuidString)"
        }
    }
}
