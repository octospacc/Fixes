import 'package:intl/intl.dart';

class Money {
  static String format(
    double value, {
    String currencyCode = 'EUR',
    String? locale,
  }) {
    final format = NumberFormat.currency(
      locale: locale ?? 'en_US',
      symbol: _symbol(currencyCode),
      decimalDigits: 2,
    );
    return format.format(value);
  }

  static String symbol(String currencyCode) => _symbol(currencyCode);

  /// Parses a price string, accepting both dot and comma as decimal
  /// separators. Handles US (1,234.56) and European (1.234,56) formats.
  ///
  /// - "1.50"    → 1.5
  /// - "1,50"    → 1.5
  /// - "1.234,56" → 1234.56
  /// - "1,234.56" → 1234.56
  /// - ""        → null
  /// - "abc"     → null
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
      // Only comma — decimal separator.
      normalized = normalized.replaceAll(',', '.');
    }

    return double.tryParse(normalized);
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