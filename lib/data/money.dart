import 'package:intl/intl.dart';

class Money {
  static String format(
    double value, {
    String currencyCode = 'EUR',
    String? locale,
  }) {
    final decimals = _needsThreeDecimals(value) ? 3 : 2;
    final format = NumberFormat.currency(
      locale: locale ?? 'en_US',
      symbol: _symbol(currencyCode),
      decimalDigits: decimals,
    );
    return format.format(value);
  }

  static String symbol(String currencyCode) => _symbol(currencyCode);

  /// Formats a price for the input field. Shows 2 decimals by default,
  /// 3 only when the value has a non-zero third decimal.
  static String formatForInput(double? value) {
    if (value == null) return '';
    if (_needsThreeDecimals(value)) return value.toStringAsFixed(3);
    return value.toStringAsFixed(2);
  }

  /// Parses a price string, accepting both dot and comma as decimal
  /// separators, and rounds to at most 3 decimal places.
  ///
  /// - "1.50"     → 1.5
  /// - "1,50"     → 1.5
  /// - "1.234,56" → 1234.56
  /// - "1,234.56" → 1234.56
  /// - "0.1955"   → 0.196  (rounded to 3 decimals)
  /// - ""         → null
  /// - "abc"      → null
  static double? parse(String text) {
    var normalized = text.trim();
    if (normalized.isEmpty) return null;

    if (normalized.contains(',') && normalized.contains('.')) {
      final lastComma = normalized.lastIndexOf(',');
      final lastDot = normalized.lastIndexOf('.');
      if (lastComma > lastDot) {
        // European: dots are thousands separators, comma is decimal.
        normalized = normalized.replaceAll('.', '').replaceAll(',', '.');
      } else {
        // US: commas are thousands separators, dot is decimal.
        normalized = normalized.replaceAll(',', '');
      }
    } else if (normalized.contains(',')) {
      normalized = normalized.replaceAll(',', '.');
    }

    final parsed = double.tryParse(normalized);
    if (parsed == null) return null;

    return (parsed * 1000).roundToDouble() / 1000;
  }

  /// True when rounding [value] to 2 decimal places would lose information.
  /// Compares the 3-decimal and 2-decimal representations directly so
  /// floating-point artefacts (e.g. 0.1 * 3 = 0.30000000000000004) do not
  /// trigger a spurious third decimal.
  static bool _needsThreeDecimals(double value) {
    return value.toStringAsFixed(3) != '${value.toStringAsFixed(2)}0';
  }

  static String _symbol(String code) {
    const symbols = {
      'USD': r'$',
      'EUR': '€',
      'GBP': '£',
      'JPY': '¥',
      'CHF': 'CHF',
      'CNY': '¥',
    };
    return symbols[code] ?? code;
  }
}