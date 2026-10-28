import SwiftUI
import SwiftData

struct ItemsView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: [SortDescriptor(\Consumable.sortOrder), SortDescriptor(\Consumable.name)])
    private var items: [Consumable]

    @Query private var entries: [ConsumptionEntry]

    @AppStorage("currencyCode") private var currencyCode = Money.currencyCode()

    @State private var editorRoute: ItemEditorRoute?
    @State private var showsArchived = false

    private var activeItems: [Consumable] {
        items.filter { !$0.isArchived }
    }

    private var archivedItems: [Consumable] {
        items.filter(\.isArchived)
    }

    private var logCountByItem: [UUID: Int] {
        Dictionary(grouping: entries.compactMap { $0.consumable?.id }, by: { $0 })
            .mapValues(\.count)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                activeSection
                if !archivedItems.isEmpty {
                    archivedSection
                }
            }
            .padding(.horizontal, TallyTheme.pagePadding)
            .padding(.top, 6)
            .padding(.bottom, 40)
            .tallyPageWidth()
        }
        .background(TallyBackground())
        .navigationTitle("Items")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(TallyTheme.canvas, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    editorRoute = .add
                } label: {
                    Label("Add item", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .tint(TallyTheme.accent)
                .accessibilityLabel("Add item")
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
        #if DEBUG
        .onAppear {
            if ProcessInfo.processInfo.arguments.contains("-openNewItem"), editorRoute == nil {
                editorRoute = .add
            }
        }
        #endif
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("YOUR LIBRARY")
                .font(TallyTheme.overlineFont)
                .tracking(1.2)
                .foregroundStyle(TallyTheme.muted)
            Text("The things you count.")
                .font(TallyTheme.displayFont)
                .foregroundStyle(TallyTheme.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            Text("Make Tally yours. Add anything countable — with an optional price.")
                .font(TallyTheme.bodyFont)
                .foregroundStyle(TallyTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var activeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeading(
                title: "Active items",
                subtitle: "\(activeItems.count) \(activeItems.count == 1 ? "item" : "items") on your shelf",
                actionTitle: "Add item",
                action: { editorRoute = .add }
            )

            if activeItems.isEmpty {
                TallyEmptyState(
                    symbol: "square.grid.2x2",
                    title: "Nothing on the shelf",
                    message: "Start with a suggestion or create your own item. The starter presets are always available from the new item screen.",
                    actionTitle: "Create an item",
                    action: { editorRoute = .add }
                )
                .tallyCard(padding: 4)
            } else {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 154, maximum: 300), spacing: 10)],
                    spacing: 10
                ) {
                    ForEach(activeItems, id: \.id) { item in
                        itemCard(item, archived: false)
                    }
                }
            }
        }
    }

    private var archivedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.easeOut(duration: 0.2)) { showsArchived.toggle() }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Archived")
                            .font(TallyTheme.sectionFont)
                            .foregroundStyle(TallyTheme.ink)
                        Text("\(archivedItems.count) hidden from quick add · history kept")
                            .font(TallyTheme.captionFont)
                            .foregroundStyle(TallyTheme.muted)
                    }
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(TallyTheme.muted)
                        .rotationEffect(.degrees(showsArchived ? 180 : 0))
                }
            }
            .buttonStyle(.plain)

            if showsArchived {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 154, maximum: 300), spacing: 10)],
                    spacing: 10
                ) {
                    ForEach(archivedItems, id: \.id) { item in
                        itemCard(item, archived: true)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func itemCard(_ item: Consumable, archived: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                ItemIcon(symbolName: item.symbolName, tint: item.color, size: 40)
                Spacer(minLength: 6)
                Menu {
                    Button {
                        editorRoute = .edit(item)
                    } label: {
                        Label("Edit item", systemImage: "pencil")
                    }
                    Button {
                        toggleArchive(item)
                    } label: {
                        Label(item.isArchived ? "Restore item" : "Archive item",
                              systemImage: item.isArchived ? "arrow.uturn.backward" : "archivebox")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(TallyTheme.muted)
                        .frame(width: 28, height: 30)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Actions for \(item.name)")
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(TallyTheme.ink)
                    .lineLimit(1)
                Text(item.category.title)
                    .font(TallyTheme.captionFont)
                    .foregroundStyle(TallyTheme.muted)
            }

            Divider().overlay(TallyTheme.hairline)

            HStack {
                if let price = item.unitPriceCents {
                    Text(Money.display(price, currencyCode: currencyCode))
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(TallyTheme.ink)
                } else {
                    Text("No price")
                        .font(TallyTheme.captionFont)
                        .foregroundStyle(TallyTheme.muted)
                }
                Spacer()
                Text("\(logCountByItem[item.id, default: 0]) logs")
                    .font(TallyTheme.captionFont)
                    .foregroundStyle(TallyTheme.muted)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(TallyTheme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(TallyTheme.hairline.opacity(0.85), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.025), radius: 10, x: 0, y: 5)
        .opacity(archived ? 0.7 : 1)
        .contentShape(Rectangle())
        .onTapGesture { editorRoute = .edit(item) }
        .contextMenu {
            Button {
                editorRoute = .edit(item)
            } label: {
                Label("Edit item", systemImage: "pencil")
            }
            Button {
                toggleArchive(item)
            } label: {
                Label(item.isArchived ? "Restore item" : "Archive item",
                      systemImage: item.isArchived ? "arrow.uturn.backward" : "archivebox")
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }

    private func toggleArchive(_ item: Consumable) {
        withAnimation(.easeOut(duration: 0.2)) {
            if item.isArchived {
                item.restore()
            } else {
                item.archive()
            }
        }
        try? modelContext.save()
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
