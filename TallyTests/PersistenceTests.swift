import XCTest
import SwiftData
@testable import Tally

final class PersistenceTests: XCTestCase {
    @MainActor
    func testItemDeletionCascadesToEntries() throws {
        let schema = Schema([Consumable.self, ConsumptionEntry.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = ModelContext(container)

        let item = Consumable(name: "Coffee", category: .drinks)
        context.insert(item)

        let entry = ConsumptionEntry(consumable: item, quantity: 2, unitPriceCents: 150)
        context.insert(entry)
        try context.save()

        XCTAssertEqual(try context.fetchCount(FetchDescriptor<ConsumptionEntry>()), 1)
        XCTAssertEqual(entry.totalSpendCents, 300)

        context.delete(item)
        try context.save()

        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Consumable>()), 0)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<ConsumptionEntry>()), 0)
    }
}
