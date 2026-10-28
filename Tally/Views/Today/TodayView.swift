import SwiftUI
import SwiftData

struct TodayView: View {
    @EnvironmentObject private var router: AppRouter
    @Environment(\.modelContext) private var modelContext
    @Environment(\.calendar) private var calendar

    @Query(sort: [SortDescriptor(\Consumable.sortOrder), SortDescriptor(\Consumable.name)])
    private var items: [Consumable]

    @Query(sort: [SortDescriptor(\ConsumptionEntry.timestamp, order: .reverse)])
    private var entries: [ConsumptionEntry]

    @AppStorage("currencyCode") private var currencyCode = Money.currencyCode()

    @State private var editorRoute: EntryEditorRoute?
    @State private var entryPendingDeletion: ConsumptionEntry?
    @State private var toast: ToastState?
    @State private var feedbackTrigger = 0

    private var activeItems: [Consumable] {
        items.filter { !$0.isArchived }
    }

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

    private var greeting: String {
        switch calendar.component(.hour, from: .now) {
        case 5..<12: "Good morning."
        case 12..<18: "Good afternoon."
        default: "Good evening."
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                summary
                quickAddSection
                ledgerSection
            }
            .padding(.horizontal, TallyTheme.pagePadding)
            .padding(.top, 6)
            .padding(.bottom, 40)
            .tallyPageWidth()
        }
        .background(TallyBackground())
        .navigationTitle("Today")
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
        .overlay(alignment: .bottom) {
            if let toast {
                ToastBanner(symbol: toast.symbol, message: toast.message, undo: toast.undo)
                    .padding(.bottom, 10)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
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

    private var header: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(TallyDateFormat.headerDate().uppercased())
                .font(TallyTheme.overlineFont)
                .tracking(1.2)
                .foregroundStyle(TallyTheme.muted)

            Text(greeting)
                .font(TallyTheme.displayFont)
                .foregroundStyle(TallyTheme.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            Text(todayEntries.isEmpty
                 ? "A clean page. What will you count first?"
                 : "Here's what today looks like so far.")
                .font(TallyTheme.bodyFont)
                .foregroundStyle(TallyTheme.muted)
        }
    }

    private var summary: some View {
        HStack(spacing: 10) {
            MetricTile(
                title: "Logged today",
                value: "\(totalQuantity)",
                detail: todayEntries.count == 1 ? "1 entry" : "\(todayEntries.count) entries",
                symbolName: "checkmark.circle.fill",
                filled: true
            )
            MetricTile(
                title: "Spent today",
                value: totalSpendCents == nil ? "—" : Money.display(totalSpendCents, currencyCode: currencyCode),
                detail: totalSpendCents == nil
                    ? "Prices are optional"
                    : (pricedEntries.count == 1 ? "1 priced entry" : "\(pricedEntries.count) priced entries"),
                symbolName: "tag.fill",
                tint: Color(hex: "A77443")
            )
        }
    }

    private var quickAddSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeading(
                title: "Quick add",
                subtitle: activeItems.isEmpty ? nil : "Tap a card to log one at this moment.",
                actionTitle: "Manage",
                action: { router.section = .items }
            )

            if activeItems.isEmpty {
                TallyEmptyState(
                    symbol: "square.grid.2x2",
                    title: "Your shelf is empty",
                    message: "Create a few things you want to keep an eye on. Coffee, cigarettes, chips, scratch cards — anything countable.",
                    actionTitle: "Set up items",
                    action: { router.section = .items }
                )
                .tallyCard(padding: 4)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(alignment: .top, spacing: 10) {
                        ForEach(activeItems, id: \.id) { item in
                            QuickAddTile(item: item, currencyCode: currencyCode) {
                                logNow(item)
                            }
                            .frame(width: 154)
                        }

                        Button {
                            router.section = .items
                        } label: {
                            VStack(spacing: 9) {
                                Image(systemName: "plus")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(TallyTheme.accent)
                                    .frame(width: 38, height: 38)
                                    .background(Circle().fill(TallyTheme.accentSoft))
                                Text("New item")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundStyle(TallyTheme.ink)
                                Text("Make it yours")
                                    .font(TallyTheme.captionFont)
                                    .foregroundStyle(TallyTheme.muted)
                            }
                            .frame(width: 154)
                            .frame(minHeight: 124)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(TallyTheme.surface.opacity(0.6))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .strokeBorder(TallyTheme.hairline, style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
                            )
                        }
                        .buttonStyle(QuickAddTileButtonStyle())
                    }
                    .padding(.vertical, 2)
                }
                .scrollClipDisabled()

                Button {
                    editorRoute = .add
                } label: {
                    Label("Log something with a specific date or time", systemImage: "calendar.badge.plus")
                        .font(TallyTheme.captionFont)
                        .foregroundStyle(TallyTheme.muted)
                }
                .buttonStyle(.plain)
                .padding(.top, 1)
            }
        }
    }

    private var ledgerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeading(
                title: "Today's ledger",
                subtitle: todayEntries.isEmpty
                    ? nil
                    : "\(totalQuantity) \(totalQuantity == 1 ? "item" : "items") counted"
            )

            if todayEntries.isEmpty {
                TallyEmptyState(
                    symbol: "text.line.first.and.arrowtriangle.forward",
                    title: "Nothing logged yet",
                    message: "Your day is still a blank page. Add something whenever you're ready.",
                    actionTitle: "Log an entry",
                    action: { editorRoute = .add }
                )
                .tallyCard(padding: 4)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(todayEntries.enumerated()), id: \.element.id) { index, entry in
                        EntryRow(
                            entry: entry,
                            currencyCode: currencyCode,
                            onEdit: { editorRoute = .edit(entry) },
                            onDelete: { entryPendingDeletion = entry },
                            onLogAgain: { logAgain(entry) }
                        )
                        .padding(.horizontal, 14)
                        .padding(.vertical, 11)
                        .contentShape(Rectangle())
                        .onTapGesture { editorRoute = .edit(entry) }

                        if index < todayEntries.count - 1 {
                            Divider()
                                .overlay(TallyTheme.hairline.opacity(0.7))
                                .padding(.leading, 66)
                        }
                    }
                }
                .padding(.vertical, 4)
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
        }
    }

    private var deleteAlertBinding: Binding<Bool> {
        Binding(
            get: { entryPendingDeletion != nil },
            set: { if !$0 { entryPendingDeletion = nil } }
        )
    }

    private func logNow(_ item: Consumable) {
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

        let toast = ToastState(
            symbol: "checkmark",
            message: "\(item.name) logged",
            undo: {
                modelContext.delete(entry)
                try? modelContext.save()
                withAnimation(.easeOut(duration: 0.2)) { self.toast = nil }
            }
        )
        present(toast)
    }

    private func logAgain(_ entry: ConsumptionEntry) {
        guard let item = entry.consumable else { return }
        let repeatEntry = ConsumptionEntry(
            consumable: item,
            quantity: entry.quantity,
            timestamp: .now,
            hasTime: true,
            unitPriceCents: entry.unitPriceCents,
            note: entry.note
        )
        modelContext.insert(repeatEntry)
        try? modelContext.save()
        feedbackTrigger += 1
        present(ToastState(symbol: "arrow.clockwise", message: "\(item.name) logged again"))
    }

    private func present(_ toast: ToastState) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            self.toast = toast
        }
        let id = toast.id
        Task {
            try? await Task.sleep(for: .seconds(3.2))
            guard !Task.isCancelled else { return }
            if self.toast?.id == id {
                withAnimation(.easeOut(duration: 0.2)) { self.toast = nil }
            }
        }
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

private struct ToastState: Identifiable {
    let id = UUID()
    let symbol: String
    let message: String
    var undo: (() -> Void)?
}
