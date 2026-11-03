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

  /// Public accessor for the currency symbol, used by UI code that
  /// wants to display the symbol without a formatted amount.
  static String symbol(String currencyCode) => _symbol(currencyCode);

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