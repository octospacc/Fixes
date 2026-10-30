import Foundation

enum Money {
    static func display(_ cents: Int?, currencyCode: String) -> String {
        guard let cents else { return "—" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.maximumFractionDigits = 2
        let amount = Decimal(cents) / Decimal(100)
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "\(currencyCode) \(amount)"
    }

    static func symbol(for currencyCode: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        return formatter.currencySymbol ?? currencyCode
    }

    /// Plain, editable amount without a symbol, using the current locale's
    /// decimal separator (for example "2,50" in Italy).
    static func editableAmount(_ cents: Int?, locale: Locale = .current) -> String {
        guard let cents else { return "" }
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        formatter.minimumFractionDigits = cents.isMultiple(of: 100) ? 0 : 2
        formatter.maximumFractionDigits = 2
        let amount = Decimal(cents) / Decimal(100)
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? ""
    }

    /// Parses either "2.50" or "2,50", ignoring a currency symbol if pasted.
    static func cents(from text: String) -> Int? {
        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return nil }
        cleaned = cleaned.filter { $0.isNumber || $0 == "." || $0 == "," }

        if cleaned.contains(","), cleaned.contains(".") {
            if let comma = cleaned.lastIndex(of: ","), let dot = cleaned.lastIndex(of: "."), comma > dot {
                cleaned = cleaned.replacingOccurrences(of: ".", with: "")
                cleaned = cleaned.replacingOccurrences(of: ",", with: ".")
            } else {
                cleaned = cleaned.replacingOccurrences(of: ",", with: "")
            }
        } else {
            cleaned = cleaned.replacingOccurrences(of: ",", with: ".")
        }

        guard let value = Decimal(string: cleaned, locale: Locale(identifier: "en_US_POSIX")) else {
            return nil
        }
        var cents = value * Decimal(100)
        var rounded = Decimal()
        NSDecimalRound(&rounded, &cents, 0, .plain)
        guard rounded >= 0 else { return nil }
        return NSDecimalNumber(decimal: rounded).intValue
    }

    static func currencyCode(for locale: Locale = .current) -> String {
        locale.currency?.identifier ?? "USD"
    }
}

enum FixesDateFormat {
    static func historyHeader(_ date: Date, calendar: Calendar = .current) -> String {
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }
        if calendar.component(.year, from: date) == calendar.component(.year, from: .now) {
            return date.formatted(.dateTime.weekday(.wide).day().month(.wide))
        }
        return date.formatted(.dateTime.weekday(.wide).day().month(.wide).year())
    }

    static func time(_ date: Date) -> String {
        date.formatted(date: .omitted, time: .shortened)
    }
}

extension Date {
    func startOfDay(calendar: Calendar = .current) -> Date {
        calendar.startOfDay(for: self)
    }
}

extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
