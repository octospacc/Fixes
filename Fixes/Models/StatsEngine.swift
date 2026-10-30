import Foundation

enum StatsRange: String, CaseIterable, Identifiable {
    case week
    case month
    case quarter

    var id: String { rawValue }

    var days: Int {
        switch self {
        case .week: 7
        case .month: 30
        case .quarter: 90
        }
    }

    var title: String {
        switch self {
        case .week: "Last 7 Days"
        case .month: "Last 30 Days"
        case .quarter: "Last 90 Days"
        }
    }
}

/// A value snapshot of an entry, keeping the statistics engine independent of
/// the persistence layer and easy to test.
struct ConsumptionRecord: Identifiable, Hashable {
    let id: UUID
    let itemID: UUID
    let itemName: String
    let category: ConsumableCategory
    let quantity: Int
    let unitPriceCents: Int?
    let timestamp: Date

    init(
        id: UUID = UUID(),
        itemID: UUID,
        itemName: String,
        category: ConsumableCategory,
        quantity: Int,
        unitPriceCents: Int?,
        timestamp: Date
    ) {
        self.id = id
        self.itemID = itemID
        self.itemName = itemName
        self.category = category
        self.quantity = quantity
        self.unitPriceCents = unitPriceCents
        self.timestamp = timestamp
    }

    init(entry: ConsumptionEntry) {
        self.init(
            id: entry.id,
            itemID: entry.consumable?.id ?? UUID(),
            itemName: entry.itemName,
            category: entry.category,
            quantity: entry.quantity,
            unitPriceCents: entry.unitPriceCents,
            timestamp: entry.timestamp
        )
    }

    var totalSpendCents: Int? {
        unitPriceCents.map { $0 * quantity }
    }
}

struct DailyPoint: Identifiable {
    let day: Date
    let quantity: Int
    let spendCents: Int

    var id: Date { day }
}

struct ItemStat: Identifiable {
    let itemID: UUID
    let name: String
    let category: ConsumableCategory
    let quantity: Int
    let entryCount: Int
    let spendCents: Int
    let hasPrice: Bool

    var id: UUID { itemID }
}

struct StatsReport {
    let range: StatsRange
    let start: Date
    let end: Date
    let totalQuantity: Int
    let entryCount: Int
    let totalSpendCents: Int
    let pricedEntryCount: Int
    let activeDays: Int
    let dailyAverage: Double
    let dailyPoints: [DailyPoint]
    let items: [ItemStat]

    var hasSpending: Bool { pricedEntryCount > 0 }
    var isEmpty: Bool { totalQuantity == 0 }
}

enum StatsEngine {
    static func report(
        records: [ConsumptionRecord],
        range: StatsRange,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> StatsReport {
        let today = calendar.startOfDay(for: now)
        let start = calendar.date(byAdding: .day, value: -(range.days - 1), to: today) ?? today
        let end = calendar.date(byAdding: .day, value: 1, to: today) ?? now

        let filtered = records.filter { record in
            record.timestamp >= start && record.timestamp < end
        }

        var dailyByDate: [Date: (quantity: Int, spendCents: Int)] = [:]
        for offset in 0..<range.days {
            if let day = calendar.date(byAdding: .day, value: offset, to: start) {
                dailyByDate[calendar.startOfDay(for: day)] = (0, 0)
            }
        }

        struct MutableItem {
            var name: String
            var category: ConsumableCategory
            var quantity = 0
            var entryCount = 0
            var spendCents = 0
            var hasPrice = false
        }

        var itemMap: [UUID: MutableItem] = [:]
        var activeDays = Set<Date>()
        var totalQuantity = 0
        var totalSpendCents = 0
        var pricedEntryCount = 0

        for record in filtered {
            let day = calendar.startOfDay(for: record.timestamp)
            let spend = record.totalSpendCents ?? 0

            var dayValue = dailyByDate[day] ?? (0, 0)
            dayValue.quantity += record.quantity
            dayValue.spendCents += spend
            dailyByDate[day] = dayValue

            totalQuantity += record.quantity
            totalSpendCents += spend
            if record.unitPriceCents != nil { pricedEntryCount += 1 }
            activeDays.insert(day)

            var item = itemMap[record.itemID] ?? MutableItem(
                name: record.itemName,
                category: record.category
            )
            item.quantity += record.quantity
            item.entryCount += 1
            item.spendCents += spend
            item.hasPrice = item.hasPrice || record.unitPriceCents != nil
            itemMap[record.itemID] = item
        }

        let dailyPoints = dailyByDate
            .map { DailyPoint(day: $0.key, quantity: $0.value.quantity, spendCents: $0.value.spendCents) }
            .sorted { $0.day < $1.day }

        let items = itemMap.map { key, value in
            ItemStat(
                itemID: key,
                name: value.name,
                category: value.category,
                quantity: value.quantity,
                entryCount: value.entryCount,
                spendCents: value.spendCents,
                hasPrice: value.hasPrice
            )
        }
        .sorted {
            if $0.quantity == $1.quantity { return $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            return $0.quantity > $1.quantity
        }

        return StatsReport(
            range: range,
            start: start,
            end: end,
            totalQuantity: totalQuantity,
            entryCount: filtered.count,
            totalSpendCents: totalSpendCents,
            pricedEntryCount: pricedEntryCount,
            activeDays: activeDays.count,
            dailyAverage: Double(totalQuantity) / Double(range.days),
            dailyPoints: dailyPoints,
            items: items
        )
    }
}
