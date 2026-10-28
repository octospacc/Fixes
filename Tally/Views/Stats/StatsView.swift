import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.calendar) private var calendar

    @Query(sort: [SortDescriptor(\ConsumptionEntry.timestamp, order: .reverse)])
    private var entries: [ConsumptionEntry]

    @AppStorage("currencyCode") private var currencyCode = Money.currencyCode()

    @State private var selectedRange: StatsRange = .month
    @State private var editorRoute: EntryEditorRoute?

    private var report: StatsReport {
        StatsEngine.report(
            records: entries.map(ConsumptionRecord.init(entry:)),
            range: selectedRange,
            calendar: calendar
        )
    }

    private var maxDailyQuantity: Int {
        max(1, report.dailyPoints.map(\.quantity).max() ?? 1)
    }

    private var maxItemQuantity: Int {
        max(1, report.items.first?.quantity ?? 1)
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    rangePicker
                    summary
                    if report.isEmpty {
                        emptyState
                    } else {
                        activityCard
                        if report.hasSpending {
                            spendingCard
                        }
                        LazyVGrid(
                            columns: [GridItem(.adaptive(minimum: 330), spacing: 14)],
                            spacing: 14
                        ) {
                            categoryCard
                            weekdayCard
                        }
                        topItemsCard
                            .id("stats-bottom")
                    }
                }
                .padding(.horizontal, TallyTheme.pagePadding)
                .padding(.top, 6)
                .padding(.bottom, 44)
                .tallyPageWidth()
            }
            #if DEBUG
            .task {
                let arguments = ProcessInfo.processInfo.arguments
                guard let index = arguments.firstIndex(of: "-statsScroll"),
                      arguments.indices.contains(index + 1) else { return }
                let targets = [
                    "spending": "stats-spending",
                    "middle": "stats-middle",
                    "bottom": "stats-bottom"
                ]
                guard let target = targets[arguments[index + 1]] else { return }
                try? await Task.sleep(for: .seconds(1))
                proxy.scrollTo(target, anchor: target == "stats-bottom" ? .bottom : .center)
            }
            #endif
        }
        .background(TallyBackground())
        .navigationTitle("Statistics")
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
        .animation(.easeInOut(duration: 0.22), value: selectedRange)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("THE NUMBERS")
                .font(TallyTheme.overlineFont)
                .tracking(1.2)
                .foregroundStyle(TallyTheme.muted)
            Text("A clearer view.")
                .font(TallyTheme.displayFont)
                .foregroundStyle(TallyTheme.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            Text("Patterns in the small choices, without judgement.")
                .font(TallyTheme.bodyFont)
                .foregroundStyle(TallyTheme.muted)
        }
    }

    private var rangePicker: some View {
        HStack(spacing: 4) {
            ForEach(StatsRange.allCases) { range in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedRange = range
                    }
                } label: {
                    Text(range.shortTitle)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(selectedRange == range ? Color.white : TallyTheme.muted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            Capsule().fill(
                                selectedRange == range
                                    ? AnyShapeStyle(TallyTheme.accentGradient)
                                    : AnyShapeStyle(Color.clear)
                            )
                        )
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selectedRange == range ? .isSelected : [])
            }
        }
        .padding(4)
        .frame(maxWidth: 330)
        .background(Capsule().fill(TallyTheme.surface))
        .overlay(Capsule().strokeBorder(TallyTheme.hairline, lineWidth: 1))
    }

    private var summary: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 148, maximum: 260), spacing: 10)],
            spacing: 10
        ) {
            MetricTile(
                title: "Logged",
                value: "\(report.totalQuantity)",
                detail: report.entryCount == 1 ? "1 entry" : "\(report.entryCount) entries",
                symbolName: "number.circle.fill",
                filled: true
            )
            MetricTile(
                title: "Spent",
                value: report.hasSpending ? Money.display(report.totalSpendCents, currencyCode: currencyCode) : "—",
                detail: report.hasSpending
                    ? (report.pricedEntryCount == 1 ? "1 priced entry" : "\(report.pricedEntryCount) priced entries")
                    : "Prices are optional",
                symbolName: "tag.fill",
                tint: Color(hex: "A77443")
            )
            MetricTile(
                title: "Active days",
                value: "\(report.activeDays)",
                detail: "of \(selectedRange.days) days",
                symbolName: "calendar",
                tint: Color(hex: "667B5D")
            )
            MetricTile(
                title: "Daily average",
                value: report.dailyAverage.formatted(.number.precision(.fractionLength(1))),
                detail: "items per day",
                symbolName: "chart.line.uptrend.xyaxis",
                tint: Color(hex: "5A739A")
            )
        }
    }

    private var emptyState: some View {
        TallyEmptyState(
            symbol: "chart.bar.xaxis",
            title: "Quiet numbers",
            message: "No entries in the last \(selectedRange.days) days. Log a few things and this page will begin to take shape.",
            actionTitle: "Log an entry",
            action: { editorRoute = .add }
        )
        .tallyCard(padding: 4)
    }

    private var activityCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeading(
                title: "Daily tally",
                subtitle: "\(selectedRange.title.lowercased()) · \(report.totalQuantity) items across \(report.activeDays) active \(report.activeDays == 1 ? "day" : "days")"
            )

            Chart {
                ForEach(report.dailyPoints) { point in
                    BarMark(
                        x: .value("Day", point.day, unit: .day),
                        y: .value("Items", point.quantity)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [TallyTheme.accent, TallyTheme.accent.opacity(0.55)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(3)
                }

                if report.dailyAverage > 0 {
                    RuleMark(y: .value("Daily average", report.dailyAverage))
                        .foregroundStyle(TallyTheme.muted.opacity(0.6))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                }
            }
            .chartYScale(domain: 0...maxDailyQuantity)
            .chartLegend(.hidden)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                    AxisGridLine().foregroundStyle(TallyTheme.hairline.opacity(0.6))
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundStyle(TallyTheme.muted)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { _ in
                    AxisGridLine().foregroundStyle(TallyTheme.hairline.opacity(0.7))
                    AxisValueLabel()
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundStyle(TallyTheme.muted)
                }
            }
            .frame(height: 185)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .tallyCard(padding: 18)
    }

    private var spendingCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeading(
                title: "Spending",
                subtitle: "\(Money.display(report.totalSpendCents, currencyCode: currencyCode)) across \(report.pricedEntryCount) priced \(report.pricedEntryCount == 1 ? "entry" : "entries")"
            )

            Chart {
                ForEach(report.dailyPoints) { point in
                    AreaMark(
                        x: .value("Day", point.day, unit: .day),
                        y: .value("Spent", Double(point.spendCents) / 100)
                    )
                    .interpolationMethod(.monotone)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [TallyTheme.accent.opacity(0.30), TallyTheme.accent.opacity(0.015)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    LineMark(
                        x: .value("Day", point.day, unit: .day),
                        y: .value("Spent", Double(point.spendCents) / 100)
                    )
                    .interpolationMethod(.monotone)
                    .foregroundStyle(TallyTheme.accent)
                    .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                }
            }
            .chartLegend(.hidden)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                    AxisGridLine().foregroundStyle(TallyTheme.hairline.opacity(0.6))
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundStyle(TallyTheme.muted)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                    AxisGridLine().foregroundStyle(TallyTheme.hairline.opacity(0.7))
                    if let amount = value.as(Double.self) {
                        AxisValueLabel {
                            Text("\(Money.symbol(for: currencyCode))\(Int(amount))")
                                .font(.system(size: 9, weight: .medium, design: .rounded))
                                .foregroundStyle(TallyTheme.muted)
                        }
                    }
                }
            }
            .frame(height: 165)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .tallyCard(padding: 18)
    }

    private var categoryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeading(title: "By category", subtitle: "Share of items logged")

            HStack(alignment: .center, spacing: 18) {
                Chart(report.categories) { stat in
                    SectorMark(
                        angle: .value("Items", stat.quantity),
                        innerRadius: .ratio(0.64),
                        angularInset: 2
                    )
                    .cornerRadius(3)
                    .foregroundStyle(stat.category.color)
                }
                .chartLegend(.hidden)
                .frame(width: 126, height: 126)
                .overlay {
                    VStack(spacing: 0) {
                        Text("\(report.totalQuantity)")
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(TallyTheme.ink)
                        Text("items")
                            .font(TallyTheme.captionFont)
                            .foregroundStyle(TallyTheme.muted)
                    }
                }

                VStack(alignment: .leading, spacing: 7) {
                    ForEach(report.categories) { stat in
                        HStack(spacing: 7) {
                            Circle()
                                .fill(stat.category.color)
                                .frame(width: 7, height: 7)
                            Text(stat.category.title)
                                .font(TallyTheme.captionFont)
                                .foregroundStyle(TallyTheme.ink)
                                .lineLimit(1)
                            Spacer(minLength: 6)
                            Text("\(stat.quantity)")
                                .font(TallyTheme.captionFont)
                                .monospacedDigit()
                                .foregroundStyle(TallyTheme.muted)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .tallyCard(padding: 18)
    }

    private var weekdayCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeading(title: "Your week", subtitle: "Total items by day of week")

            Chart(report.weekdays) { stat in
                BarMark(
                    x: .value("Weekday", stat.shortLabel),
                    y: .value("Items", stat.quantity)
                )
                .foregroundStyle(TallyTheme.accent.opacity(0.85))
                .cornerRadius(4)
            }
            .chartLegend(.hidden)
            .chartXAxis {
                AxisMarks(values: report.weekdays.map(\.shortLabel)) { _ in
                    AxisValueLabel()
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .foregroundStyle(TallyTheme.muted)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { _ in
                    AxisGridLine().foregroundStyle(TallyTheme.hairline.opacity(0.7))
                    AxisValueLabel()
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundStyle(TallyTheme.muted)
                }
            }
            .frame(height: 156)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .tallyCard(padding: 18)
    }

    private var topItemsCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            SectionHeading(title: "What you reach for", subtitle: "Top items in this window")

            VStack(spacing: 13) {
                ForEach(Array(report.items.prefix(6).enumerated()), id: \.element.id) { index, item in
                    HStack(alignment: .center, spacing: 11) {
                        Text("\(index + 1)")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(TallyTheme.muted)
                            .frame(width: 14, alignment: .trailing)

                        ItemIcon(symbolName: item.symbolName, tint: Color(hex: item.colorHex), size: 32)

                        VStack(alignment: .leading, spacing: 6) {
                            HStack(alignment: .firstTextBaseline) {
                                Text(item.name)
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundStyle(TallyTheme.ink)
                                    .lineLimit(1)
                                Spacer()
                                Text("\(item.quantity)")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .monospacedDigit()
                                    .foregroundStyle(TallyTheme.ink)
                                if item.hasPrice {
                                    Text(Money.display(item.spendCents, currencyCode: currencyCode))
                                        .font(TallyTheme.captionFont)
                                        .monospacedDigit()
                                        .foregroundStyle(TallyTheme.muted)
                                        .frame(minWidth: 46, alignment: .trailing)
                                }
                            }

                            GeometryReader { proxy in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(TallyTheme.hairline.opacity(0.7))
                                        .frame(height: 4)
                                    Capsule()
                                        .fill(Color(hex: item.colorHex))
                                        .frame(
                                            width: max(4, proxy.size.width * CGFloat(item.quantity) / CGFloat(maxItemQuantity)),
                                            height: 4
                                        )
                                }
                            }
                            .frame(height: 4)
                        }
                    }
                }
            }

            if report.items.count > 6 {
                Text("+ \(report.items.count - 6) more \(report.items.count - 6 == 1 ? "item" : "items")")
                    .font(TallyTheme.captionFont)
                    .foregroundStyle(TallyTheme.muted)
                    .padding(.leading, 25)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .tallyCard(padding: 18)
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
