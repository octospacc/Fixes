import XCTest
@testable import Tally

final class MoneyTests: XCTestCase {
    func testParsesCommonDecimalSeparators() {
        XCTAssertEqual(Money.cents(from: "2.50"), 250)
        XCTAssertEqual(Money.cents(from: "2,50"), 250)
        XCTAssertEqual(Money.cents(from: " 12 "), 1200)
    }

    func testParsesBothGroupingSeparators() {
        XCTAssertEqual(Money.cents(from: "1.234,56"), 123_456)
        XCTAssertEqual(Money.cents(from: "1,234.56"), 123_456)
    }

    func testIgnoresCurrencySymbolsAndRejectsInvalidInput() {
        XCTAssertEqual(Money.cents(from: "€ 4,20"), 420)
        XCTAssertNil(Money.cents(from: ""))
        XCTAssertNil(Money.cents(from: "not a price"))
    }

    func testEntryTotalMultipliesQuantityByUnitPrice() {
        let entry = ConsumptionEntry(
            consumable: nil,
            quantity: 3,
            unitPriceCents: 275
        )
        XCTAssertEqual(entry.totalSpendCents, 825)
    }
}
