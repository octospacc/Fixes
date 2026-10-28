import Foundation
import SwiftData

/// Curated starting points offered on first launch and when adding an item.
struct ConsumablePreset: Identifiable, Hashable {
    let id: String
    let name: String
    let symbolName: String
    let colorHex: String
    let category: ConsumableCategory
    let suggestedPriceCents: Int?

    init(
        id: String,
        name: String,
        symbolName: String,
        colorHex: String,
        category: ConsumableCategory,
        suggestedPriceCents: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.symbolName = symbolName
        self.colorHex = colorHex
        self.category = category
        self.suggestedPriceCents = suggestedPriceCents
    }

    func makeConsumable(sortOrder: Int) -> Consumable {
        Consumable(
            name: name,
            symbolName: symbolName,
            colorHex: colorHex,
            category: category,
            unitPriceCents: nil,
            sortOrder: sortOrder
        )
    }

    static let starterSet: [ConsumablePreset] = [
        .init(id: "coffee", name: "Coffee", symbolName: "cup.and.saucer.fill", colorHex: "A77443", category: .drinks),
        .init(id: "cigarettes", name: "Cigarettes", symbolName: "smoke.fill", colorHex: "B65B43", category: .smoking),
        .init(id: "tea", name: "Tea", symbolName: "mug.fill", colorHex: "5D8A86", category: .drinks),
        .init(id: "chips", name: "Chips", symbolName: "takeoutbag.and.cup.and.straw.fill", colorHex: "C7973A", category: .snacks),
        .init(id: "scratch-card", name: "Scratch card", symbolName: "ticket.fill", colorHex: "826AA6", category: .gambling),
        .init(id: "lunch-out", name: "Lunch out", symbolName: "fork.knife", colorHex: "667B5D", category: .food),
        .init(id: "gaming-session", name: "Gaming session", symbolName: "gamecontroller.fill", colorHex: "5A739A", category: .gaming)
    ]

    /// Additional suggestions shown while creating a custom item.
    static let extraSuggestions: [ConsumablePreset] = [
        .init(id: "beer", name: "Beer", symbolName: "beer.mug.fill", colorHex: "B58A3C", category: .drinks),
        .init(id: "soda", name: "Soda", symbolName: "bubbles.and.sparkles.fill", colorHex: "8B6AAE", category: .drinks),
        .init(id: "candy", name: "Candy", symbolName: "birthday.cake.fill", colorHex: "C26A72", category: .snacks),
        .init(id: "takeaway-dinner", name: "Takeaway dinner", symbolName: "takeoutbag.and.cup.and.straw.fill", colorHex: "A45E48", category: .food),
        .init(id: "online-purchase", name: "Online purchase", symbolName: "shippingbox.fill", colorHex: "6C7B6A", category: .other),
        .init(id: "painkiller", name: "Painkiller", symbolName: "pill.fill", colorHex: "6D7F96", category: .wellness)
    ]

    static var allSuggestions: [ConsumablePreset] {
        starterSet + extraSuggestions
    }
}

@MainActor
enum PresetSeeder {
    private static let seedKey = "tally.didSeedStarterPresets.v1"

    /// Seeds the seven starter items exactly once. An intentionally empty
    /// library is never repopulated on a later launch.
    static func seedIfNeeded(in context: ModelContext, defaults: UserDefaults = .standard) {
        guard !defaults.bool(forKey: seedKey) else { return }

        var descriptor = FetchDescriptor<Consumable>()
        descriptor.fetchLimit = 1
        let existing = (try? context.fetch(descriptor)) ?? []

        if existing.isEmpty {
            for (index, preset) in ConsumablePreset.starterSet.enumerated() {
                context.insert(preset.makeConsumable(sortOrder: index))
            }
            try? context.save()
        }
        defaults.set(true, forKey: seedKey)
    }
}

#if DEBUG
@MainActor
enum DemoDataSeeder {
    private static let demoKey = "tally.didSeedDemoData.v1"

    /// Optional, deterministic sample history for screenshots and for trying
    /// out the statistics screen. Launch the debug app with `-demoData`.
    static func seedIfRequested(in context: ModelContext, defaults: UserDefaults = .standard) {
        guard ProcessInfo.processInfo.arguments.contains("-demoData"),
              !defaults.bool(forKey: demoKey) else { return }
        defaults.set(true, forKey: demoKey)

        let descriptor = FetchDescriptor<Consumable>(sortBy: [SortDescriptor(\.sortOrder)])
        var items = (try? context.fetch(descriptor)) ?? []
        if items.isEmpty {
            PresetSeeder.seedIfNeeded(in: context, defaults: defaults)
            items = (try? context.fetch(descriptor)) ?? []
        }
        guard !items.isEmpty else { return }

        let priceByID: [String: Int] = [
            "coffee": 130, "cigarettes": 620, "tea": 110, "chips": 260,
            "scratch-card": 500, "lunch-out": 1450, "gaming-session": 0
        ]
        for item in items {
            if let preset = ConsumablePreset.allSuggestions.first(where: { $0.name == item.name }) {
                item.unitPriceCents = priceByID[preset.id] == 0 ? nil : (priceByID[preset.id] ?? preset.suggestedPriceCents)
            }
        }

        let calendar = Calendar.current
        let now = Date.now
        let today = calendar.startOfDay(for: now)
        var generator = SeededGenerator(seed: 0x7A11)
        let scheduleByPreset: [String: (count: ClosedRange<Int>, hours: ClosedRange<Int>)] = [
            "coffee": (1...2, 7...10),
            "cigarettes": (2...5, 9...22),
            "tea": (0...1, 14...18),
            "chips": (0...1, 16...21),
            "scratch-card": (0...1, 11...20),
            "lunch-out": (0...1, 12...14),
            "gaming-session": (0...2, 18...23)
        ]

        for dayOffset in stride(from: 34, through: 0, by: -1) {
            guard let day = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            let weekday = calendar.component(.weekday, from: day)
            for item in items {
                guard let preset = ConsumablePreset.allSuggestions.first(where: { $0.name == item.name }),
                      let schedule = scheduleByPreset[preset.id] else { continue }

                var count = Int.random(in: schedule.count, using: &generator)
                if preset.id == "lunch-out" && (weekday == 1 || weekday == 7) { count = 0 }
                if preset.id == "scratch-card" && generator.next() % 3 != 0 { count = 0 }
                if dayOffset == 0 { count = max(1, min(count, 2)) }

                for index in 0..<count {
                    let hour = Int.random(in: schedule.hours, using: &generator)
                    let minute = [5, 12, 24, 37, 48, 55].randomElement(using: &generator) ?? 15
                    var components = calendar.dateComponents([.year, .month, .day], from: day)
                    components.hour = hour
                    components.minute = minute
                    var timestamp = calendar.date(from: components) ?? day
                    if dayOffset == 0, timestamp > now {
                        timestamp = calendar.date(byAdding: .minute, value: -(index + 1) * 11, to: now) ?? now
                    }
                    let quantity = preset.id == "cigarettes" && generator.next() % 4 == 0 ? 2 : 1
                    let unitPrice = priceByID[preset.id] == 0 ? nil : priceByID[preset.id]
                    let entry = ConsumptionEntry(
                        consumable: item,
                        quantity: quantity,
                        timestamp: timestamp,
                        hasTime: true,
                        unitPriceCents: unitPrice
                    )
                    context.insert(entry)
                }
            }
        }
        try? context.save()
    }
}

/// Small deterministic RNG so sample data is stable between launches.
private struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
#endif
