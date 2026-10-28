import XCTest
@testable import Tally

final class StatsEngineTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.firstWeekday = 2
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 12, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    private func record(
        name: String = "Coffee",
        category: ConsumableCategory = .drinks,
        quantity: Int = 1,
        price: Int? = nil,
        timestamp: Date,
        itemID: UUID = UUID()
    ) -> ConsumptionRecord {
        ConsumptionRecord(
            itemID: itemID,
            itemName: name,
            itemSymbolName: "cup.and.saucer.fill",
            colorHex: "A77443",
            category: category,
            quantity: quantity,
            unitPriceCents: price,
            timestamp: timestamp,
            hasTime: true
        )
    }

    func testTotalsAndPriceSnapshots() {
        let now = date(2026, 10, 27)
        let records = [
            record(name: "Coffee", quantity: 2, price: 130, timestamp: date(2026, 10, 27, 8)),
            record(name: "Cigarettes", category: .smoking, quantity: 3, price: 620, timestamp: date(2026, 10, 26, 21)),
            record(name: "Tea", quantity: 1, price: nil, timestamp: date(2026, 10, 25, 16))
        ]

        let report = StatsEngine.report(records: records, range: .week, now: now, calendar: calendar)

        XCTAssertEqual(report.totalQuantity, 6)
        XCTAssertEqual(report.entryCount, 3)
        XCTAssertEqual(report.pricedEntryCount, 2)
        XCTAssertEqual(report.totalSpendCents, 2 * 130 + 3 * 620)
        XCTAssertEqual(report.activeDays, 3)
        XCTAssertTrue(report.hasSpending)
        XCTAssertEqual(report.dailyPoints.count, 7)
        XCTAssertEqual(report.dailyAverage, 6.0 / 7.0, accuracy: 0.001)
    }

    func testRangeExcludesEntriesBeforeWindowAndIncludesFutureToday() {
        let now = date(2026, 10, 27, 9)
        let records = [
            record(quantity: 2, timestamp: date(2026, 10, 20, 23, 59)),
            record(quantity: 4, timestamp: date(2026, 10, 21, 0, 1)),
            record(quantity: 1, timestamp: date(2026, 10, 27, 23, 50))
        ]

        let report = StatsEngine.report(records: records, range: .week, now: now, calendar: calendar)

        XCTAssertEqual(report.totalQuantity, 5)
        XCTAssertEqual(report.entryCount, 2)
        XCTAssertEqual(report.activeDays, 2)
    }

    func testItemsCategoriesAndWeekdays() {
        let now = date(2026, 10, 27)
        let coffeeID = UUID()
        let records = [
            record(name: "Coffee", category: .drinks, quantity: 2, price: 100, timestamp: date(2026, 10, 26), itemID: coffeeID),
            record(name: "Coffee", category: .drinks, quantity: 1, price: 100, timestamp: date(2026, 10, 27), itemID: coffeeID),
            record(name: "Chips", category: .snacks, quantity: 3, timestamp: date(2026, 10, 27, 18))
        ]

        let report = StatsEngine.report(records: records, range: .week, now: now, calendar: calendar)

        XCTAssertEqual(report.items.count, 2)
        XCTAssertEqual(report.items.first?.name, "Chips")
        XCTAssertEqual(report.items.first?.quantity, 3)
        XCTAssertEqual(report.categories.first?.category, .drinks)
        XCTAssertEqual(report.categories.first?.quantity, 3)

        // Monday 26 October has two items, Tuesday has four.
        XCTAssertEqual(report.weekdays.first?.weekday, 2)
        XCTAssertEqual(report.weekdays.first?.quantity, 2)
        XCTAssertEqual(report.weekdays[1].quantity, 4)
    }

    func testNoPricesMeansNoSpendingChart() {
        let now = date(2026, 10, 27)
        let report = StatsEngine.report(
            records: [record(timestamp: now)],
            range: .month,
            now: now,
            calendar: calendar
        )

        XCTAssertFalse(report.hasSpending)
        XCTAssertEqual(report.totalSpendCents, 0)
        XCTAssertEqual(report.pricedEntryCount, 0)
    }

    func testEmptyReportHasContinuousDaysAndZeroes() {
        let now = date(2026, 10, 27)
        let report = StatsEngine.report(records: [], range: .quarter, now: now, calendar: calendar)

        XCTAssertTrue(report.isEmpty)
        XCTAssertEqual(report.dailyPoints.count, 90)
        XCTAssertEqual(report.totalQuantity, 0)
        XCTAssertEqual(report.activeDays, 0)
        XCTAssertTrue(report.items.isEmpty)
        XCTAssertEqual(report.dailyAverage, 0)
    }
}
