import Foundation
import SwiftData

/// Curated starting points offered while adding an item.
struct ConsumablePreset: Identifiable, Hashable {
    let id: String
    let name: String
    let category: ConsumableCategory

    func makeConsumable() -> Consumable {
        Consumable(name: name, category: category)
    }

    static let starterSet: [ConsumablePreset] = [
        .init(id: "coffee", name: "Coffee", category: .drinks),
        .init(id: "cigarettes", name: "Cigarettes", category: .smoking),
        .init(id: "tea", name: "Tea", category: .drinks),
        .init(id: "chips", name: "Chips", category: .snacks),
        .init(id: "scratch-card", name: "Scratch card", category: .gambling),
        .init(id: "lunch-out", name: "Lunch out", category: .food),
        .init(id: "gaming-session", name: "Gaming session", category: .gaming)
    ]

    static let extraSuggestions: [ConsumablePreset] = [
        .init(id: "beer", name: "Beer", category: .drinks),
        .init(id: "soda", name: "Soda", category: .drinks),
        .init(id: "candy", name: "Candy", category: .snacks),
        .init(id: "takeaway-dinner", name: "Takeaway dinner", category: .food),
        .init(id: "online-purchase", name: "Online purchase", category: .other),
        .init(id: "painkiller", name: "Painkiller", category: .wellness)
    ]

    static var allSuggestions: [ConsumablePreset] {
        starterSet + extraSuggestions
    }
}

@MainActor
enum StarterItems {
    static func add(to context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<Consumable>())) ?? []
        let existingNames = Set(existing.map(\.normalizedName))

        for preset in ConsumablePreset.starterSet where !existingNames.contains(preset.name.lowercased()) {
            context.insert(preset.makeConsumable())
        }
        try? context.save()
    }
}

#if DEBUG
@MainActor
enum DemoDataSeeder {
    private static let demoKey = "fixes.didSeedDemoData.v2"

    /// Optional, deterministic sample history for screenshots and for trying
    /// out the statistics screen. Launch the debug app with `-demoData`.
    static func seedIfRequested(in context: ModelContext, defaults: UserDefaults = .standard) {
        guard ProcessInfo.processInfo.arguments.contains("-demoData"),
              !defaults.bool(forKey: demoKey) else { return }
        defaults.set(true, forKey: demoKey)

        var items = (try? context.fetch(FetchDescriptor<Consumable>(sortBy: [SortDescriptor(\.createdAt)]))) ?? []
        if items.isEmpty {
            StarterItems.add(to: context)
            items = (try? context.fetch(FetchDescriptor<Consumable>(sortBy: [SortDescriptor(\.createdAt)]))) ?? []
        }
        guard !items.isEmpty else { return }

        let priceByID: [String: Int] = [
            "coffee": 130, "cigarettes": 620, "tea": 110, "chips": 260,
            "scratch-card": 500, "lunch-out": 1450, "gaming-session": 0
        ]
        for item in items {
            if let preset = ConsumablePreset.allSuggestions.first(where: { $0.name == item.name }) {
                item.unitPriceCents = priceByID[preset.id] == 0 ? nil : priceByID[preset.id]
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
