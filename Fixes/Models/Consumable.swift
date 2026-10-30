import Foundation
import SwiftData

/// A thing the user counts, such as coffee, cigarettes, or gaming sessions.
///
/// All stored properties have defaults and no unique constraints so the model
/// is compatible with CloudKit-backed SwiftData.
@Model
final class Consumable {
    var id: UUID = UUID()
    var name: String = ""
    var categoryRawValue: String = ConsumableCategory.other.rawValue
    var unitPriceCents: Int?
    var createdAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \ConsumptionEntry.consumable)
    var entries: [ConsumptionEntry]? = []

    init(
        id: UUID = UUID(),
        name: String,
        category: ConsumableCategory,
        unitPriceCents: Int? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.categoryRawValue = category.rawValue
        self.unitPriceCents = unitPriceCents
        self.createdAt = createdAt
    }

    var category: ConsumableCategory {
        get { ConsumableCategory(rawValue: categoryRawValue) ?? .other }
        set { categoryRawValue = newValue.rawValue }
    }

    var normalizedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
