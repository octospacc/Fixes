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
        case .week: "Last 7 days"
        case .month: "Last 30 days"
        case .quarter: "Last 90 days"
        }
    }

    var shortTitle: String {
        switch self {
        case .week: "7 days"
        case .month: "30 days"
        case .quarter: "90 days"
        }
    }
}

/// A value snapshot of an entry, keeping the statistics engine independent of
/// the persistence layer and easy to test.
struct ConsumptionRecord: Identifiable, Hashable {
    let id: UUID
    let itemID: UUID
    let itemName: String
    let itemSymbolName: String
    let colorHex: String
    let category: ConsumableCategory
    let quantity: Int
    let unitPriceCents: Int?
    let timestamp: Date
    let hasTime: Bool

    init(
        id: UUID = UUID(),
        itemID: UUID,
        itemName: String,
        itemSymbolName: String,
        colorHex: String,
        category: ConsumableCategory,
        quantity: Int,
        unitPriceCents: Int?,
        timestamp: Date,
        hasTime: Bool
    ) {
        self.id = id
        self.itemID = itemID
        self.itemName = itemName
        self.itemSymbolName = itemSymbolName
        self.colorHex = colorHex
        self.category = category
        self.quantity = quantity
        self.unitPriceCents = unitPriceCents
        self.timestamp = timestamp
        self.hasTime = hasTime
    }

    init(entry: ConsumptionEntry) {
        self.init(
            id: entry.id,
            itemID: entry.consumable?.id ?? UUID(),
            itemName: entry.itemName,
            itemSymbolName: entry.itemSymbolName,
            colorHex: entry.consumable?.colorHex ?? "7A7C74",
            category: entry.category,
            quantity: entry.quantity,
            unitPriceCents: entry.unitPriceCents,
            timestamp: entry.timestamp,
            hasTime: entry.hasTime
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

struct CategoryStat: Identifiable {
    let category: ConsumableCategory
    let quantity: Int
    let spendCents: Int
    let hasPrice: Bool

    var id: String { category.rawValue }
}

struct ItemStat: Identifiable {
    let itemID: UUID
    let name: String
    let symbolName: String
    let colorHex: String
    let category: ConsumableCategory
    let quantity: Int
    let entryCount: Int
    let spendCents: Int
    let hasPrice: Bool

    var id: UUID { itemID }
}

struct WeekdayStat: Identifiable {
    let weekday: Int
    let shortLabel: String
    let fullLabel: String
    let quantity: Int

    var id: Int { weekday }
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
    let categories: [CategoryStat]
    let items: [ItemStat]
    let weekdays: [WeekdayStat]

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
        let fallbackStart = calendar.date(byAdding: .day, value: -(range.days - 1), to: today) ?? today
        let end = calendar.date(byAdding: .day, value: 1, to: today) ?? now
        let start = fallbackStart

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
            var symbol: String
            var colorHex: String
            var category: ConsumableCategory
            var quantity: Int
            var entryCount: Int
            var spendCents: Int
            var hasPrice: Bool
        }

        var itemMap: [UUID: MutableItem] = [:]
        var categoryMap: [ConsumableCategory: (quantity: Int, spendCents: Int, hasPrice: Bool)] = [:]
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
                symbol: record.itemSymbolName,
                colorHex: record.colorHex,
                category: record.category,
                quantity: 0,
                entryCount: 0,
                spendCents: 0,
                hasPrice: false
            )
            item.quantity += record.quantity
            item.entryCount += 1
            item.spendCents += spend
            item.hasPrice = item.hasPrice || record.unitPriceCents != nil
            itemMap[record.itemID] = item

            var categoryValue = categoryMap[record.category] ?? (0, 0, false)
            categoryValue.quantity += record.quantity
            categoryValue.spendCents += spend
            categoryValue.hasPrice = categoryValue.hasPrice || record.unitPriceCents != nil
            categoryMap[record.category] = categoryValue
        }

        let dailyPoints = dailyByDate
            .map { DailyPoint(day: $0.key, quantity: $0.value.quantity, spendCents: $0.value.spendCents) }
            .sorted { $0.day < $1.day }

        let items = itemMap.map { key, value in
            ItemStat(
                itemID: key,
                name: value.name,
                symbolName: value.symbol,
                colorHex: value.colorHex,
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

        let categories = categoryMap.map { key, value in
            CategoryStat(
                category: key,
                quantity: value.quantity,
                spendCents: value.spendCents,
                hasPrice: value.hasPrice
            )
        }
        .sorted {
            if $0.quantity == $1.quantity { return $0.category.title < $1.category.title }
            return $0.quantity > $1.quantity
        }

        let weekdaySymbols = calendar.shortWeekdaySymbols
        let weekdayFullSymbols = calendar.weekdaySymbols
        let orderedWeekdayIndices = (0..<7).map { (calendar.firstWeekday - 1 + $0) % 7 }
        let weekdayStats = orderedWeekdayIndices.map { symbolIndex in
            let weekday = symbolIndex + 1
            let total = dailyPoints
                .filter { calendar.component(.weekday, from: $0.day) == weekday }
                .reduce(0) { $0 + $1.quantity }
            return WeekdayStat(
                weekday: weekday,
                shortLabel: weekdaySymbols[symbolIndex],
                fullLabel: weekdayFullSymbols[symbolIndex],
                quantity: total
            )
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
            categories: categories,
            items: items,
            weekdays: weekdayStats
        )
    }
}
