import Foundation
import SwiftData

/// One logged occurrence of a consumable.
///
/// Price snapshots are kept on the entry so later price changes do not rewrite
/// history. All stored properties have defaults for CloudKit compatibility.
@Model
final class ConsumptionEntry {
    var id: UUID = UUID()
    var quantity: Int = 1
    var unitPriceCents: Int?
    var timestamp: Date = Date()
    var hasTime: Bool = true
    var note: String = ""
    var consumable: Consumable?

    init(
        id: UUID = UUID(),
        consumable: Consumable?,
        quantity: Int = 1,
        timestamp: Date = .now,
        hasTime: Bool = true,
        unitPriceCents: Int? = nil,
        note: String = ""
    ) {
        self.id = id
        self.consumable = consumable
        self.quantity = quantity
        self.timestamp = timestamp
        self.hasTime = hasTime
        self.unitPriceCents = unitPriceCents
        self.note = note
    }

    var totalSpendCents: Int? {
        guard let unitPriceCents else { return nil }
        return unitPriceCents * quantity
    }

    var category: ConsumableCategory {
        consumable?.category ?? .other
    }

    var itemName: String {
        consumable?.name ?? "Deleted item"
    }
}
