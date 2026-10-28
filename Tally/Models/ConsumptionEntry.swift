import Foundation
import SwiftData
import SwiftUI

/// One logged occurrence of a consumable.
@Model
final class ConsumptionEntry {
    @Attribute(.unique) var id: UUID
    var quantity: Int
    /// Price per unit at the time of logging, in minor currency units.
    /// Kept on the entry so later price changes do not rewrite history.
    var unitPriceCents: Int?
    var timestamp: Date
    /// When false, the entry belongs to the day but has no meaningful time.
    var hasTime: Bool
    var note: String
    var createdAt: Date
    var consumable: Consumable?

    init(
        id: UUID = UUID(),
        consumable: Consumable?,
        quantity: Int = 1,
        timestamp: Date = .now,
        hasTime: Bool = true,
        unitPriceCents: Int? = nil,
        note: String = "",
        createdAt: Date = .now
    ) {
        self.id = id
        self.consumable = consumable
        self.quantity = quantity
        self.timestamp = timestamp
        self.hasTime = hasTime
        self.unitPriceCents = unitPriceCents
        self.note = note
        self.createdAt = createdAt
    }

    var totalSpendCents: Int? {
        guard let unitPriceCents else { return nil }
        return unitPriceCents * quantity
    }

    var category: ConsumableCategory {
        consumable?.category ?? .other
    }

    var itemName: String {
        consumable?.name ?? "Removed item"
    }

    var itemSymbolName: String {
        consumable?.symbolName ?? "questionmark"
    }

    var itemColor: Color {
        consumable?.color ?? .gray
    }
}
