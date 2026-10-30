import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Environment(\.calendar) private var calendar

    @Query(sort: [SortDescriptor(\ConsumptionEntry.timestamp, order: .reverse)])
    private var entries: [ConsumptionEntry]

    @AppStorage("currencyCode") private var currencyCode = Money.currencyCode()

    @State private var selectedRange: StatsRange = .month
    @State private var showingEntryEditor = false

    private var report: StatsReport {
        StatsEngine.report(
            records: entries.map(ConsumptionRecord.init(entry:)),
            range: selectedRange,
            calendar: calendar
        )
    }

    var body: some View {
        List {
            Section {
                Picker("Range", selection: $selectedRange) {
                    ForEach(StatsRange.allCases) { range in
                        Text("\(range.days) days").tag(range)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Summary") {
                LabeledContent("Items", value: "\(report.totalQuantity)")
                LabeledContent("Entries", value: "\(report.entryCount)")
                LabeledContent("Spent") {
                    Text(report.hasSpending ? Money.display(report.totalSpendCents, currencyCode: currencyCode) : "—")
                }
                LabeledContent("Active days", value: "\(report.activeDays) of \(selectedRange.days)")
                LabeledContent("Daily average", value: report.dailyAverage.formatted(.number.precision(.fractionLength(1))))
            }

            if report.isEmpty {
                // Removed the Section wrapper and applied modifiers to center it cleanly
                ContentUnavailableView(
                    "No data",
                    systemImage: "chart.bar",
                    description: Text("No entries in this range.")
                )
                .frame(maxWidth: .infinity, minHeight: 240)
                .listRowBackground(Color.clear)
            } else {
                Section("Daily counts") {
                    Chart(report.dailyPoints) { point in
                        BarMark(
                            x: .value("Date", point.day, unit: .day),
                            y: .value("Items", point.quantity)
                        )
                        .foregroundStyle(Color.accentColor)
                    }
                    .frame(height: 220)
                }

                if report.hasSpending {
                    Section("Spending") {
                        Chart(report.dailyPoints) { point in
                            LineMark(
                                x: .value("Date", point.day, unit: .day),
                                y: .value("Spent", Double(point.spendCents) / 100)
                            )
                            .foregroundStyle(Color.accentColor)
                        }
                        .frame(height: 180)
                    }
                }

                Section("Top items") {
                    ForEach(report.items.prefix(10)) { item in
                        HStack(spacing: 12) {
                            Image(systemName: item.category.systemImage)
                                .foregroundStyle(.secondary)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name)
                                if item.hasPrice {
                                    Text(Money.display(item.spendCents, currencyCode: currencyCode))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Text("\(item.quantity)")
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Statistics")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingEntryEditor = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add entry")
            }
        }
        .sheet(isPresented: $showingEntryEditor) {
            EntryEditorView()
        }
    }
}
