import Foundation
import SwiftData
import SwiftUI

/// A thing the user counts, such as coffee, cigarettes, or gaming sessions.
@Model
final class Consumable {
    @Attribute(.unique) var id: UUID
    var name: String
    var symbolName: String
    var colorHex: String
    var categoryRawValue: String
    /// Optional price for one unit, stored in the currency's minor unit.
    var unitPriceCents: Int?
    var createdAt: Date
    var sortOrder: Int
    var archivedAt: Date?

    @Relationship(deleteRule: .cascade, inverse: \ConsumptionEntry.consumable)
    var entries: [ConsumptionEntry] = []

    init(
        id: UUID = UUID(),
        name: String,
        symbolName: String,
        colorHex: String,
        category: ConsumableCategory,
        unitPriceCents: Int? = nil,
        createdAt: Date = .now,
        sortOrder: Int = 0,
        archivedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.symbolName = symbolName
        self.colorHex = colorHex
        self.categoryRawValue = category.rawValue
        self.unitPriceCents = unitPriceCents
        self.createdAt = createdAt
        self.sortOrder = sortOrder
        self.archivedAt = archivedAt
    }

    var category: ConsumableCategory {
        get { ConsumableCategory(rawValue: categoryRawValue) ?? .other }
        set { categoryRawValue = newValue.rawValue }
    }

    var isArchived: Bool { archivedAt != nil }

    var color: Color { Color(hex: colorHex) }

    func archive(at date: Date = .now) {
        archivedAt = date
    }

    func restore() {
        archivedAt = nil
    }
}

extension Consumable {
    /// An unused, user-facing duplicate check used by the preset picker.
    var normalizedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
