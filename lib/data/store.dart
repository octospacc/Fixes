import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class Store extends ChangeNotifier {
  static const _kItems = 'items';
  static const _kEntries = 'entries';
  static const _kDayStartHour = 'dayStartHour';
  static const _kCurrency = 'currency';

  static const _defaultCurrency = 'EUR';

  final SharedPreferences _prefs;
  List<Item> _items = [];
  List<Entry> _entries = [];
  int _dayStartHour = 0;
  String _currencyCode = _defaultCurrency;

  Store._(this._prefs) {
    _load();
  }

  static Future<Store> open() async {
    final prefs = await SharedPreferences.getInstance();
    return Store._(prefs);
  }

  List<Item> get items => _items;
  List<Entry> get entries => _entries;
  int get dayStartHour => _dayStartHour;
  String get currencyCode => _currencyCode;

  Future<void> setDayStartHour(int hour) async {
    final clamped = hour.clamp(0, 23);
    if (clamped == _dayStartHour) return;
    _dayStartHour = clamped;
    await _prefs.setInt(_kDayStartHour, clamped);
    notifyListeners();
  }

  Future<void> setCurrencyCode(String code) async {
    if (code == _currencyCode) return;
    _currencyCode = code;
    await _prefs.setString(_kCurrency, code);
    notifyListeners();
  }

  Item? itemById(String id) {
    for (final item in _items) {
      if (item.id == id) return item;
    }
    return null;
  }

  DateTime logicalDay(DateTime dt) {
    final adjusted = dt.subtract(Duration(hours: _dayStartHour));
    return DateTime(adjusted.year, adjusted.month, adjusted.day);
  }

  (DateTime, DateTime) logicalDayRange(DateTime anchor) {
    final adjusted = anchor.subtract(Duration(hours: _dayStartHour));
    final start = DateTime(adjusted.year, adjusted.month, adjusted.day)
        .add(Duration(hours: _dayStartHour));
    final end = start.add(const Duration(days: 1));
    return (start, end);
  }

  List<Entry> entriesForDay(DateTime anchor) {
    final (start, end) = logicalDayRange(anchor);
    return _entries
        .where((e) => !e.date.isBefore(start) && e.date.isBefore(end))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  List<Entry> get entriesSortedByDate {
    return List<Entry>.from(_entries)
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> saveItem(Item item) async {
    final i = _items.indexWhere((x) => x.id == item.id);
    if (i >= 0) {
      _items[i] = item;
    } else {
      _items.add(item);
    }
    await _persist();
    notifyListeners();
  }

  Future<void> deleteItem(String id) async {
    _items.removeWhere((i) => i.id == id);
    _entries.removeWhere((e) => e.itemId == id);
    await _persist();
    notifyListeners();
  }

  Future<void> saveEntry(Entry entry) async {
    final i = _entries.indexWhere((e) => e.id == entry.id);
    if (i >= 0) {
      _entries[i] = entry;
    } else {
      _entries.add(entry);
    }
    await _persist();
    notifyListeners();
  }

  Future<void> deleteEntry(String id) async {
    _entries.removeWhere((e) => e.id == id);
    await _persist();
    notifyListeners();
  }

  void _load() {
    try {
      final raw = _prefs.getString(_kItems);
      if (raw != null) {
        _items = (jsonDecode(raw) as List)
            .map((j) => Item.fromJson(j as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Failed to load items: $e');
      _items = [];
    }
    try {
      final raw = _prefs.getString(_kEntries);
      if (raw != null) {
        _entries = (jsonDecode(raw) as List)
            .map((j) => Entry.fromJson(j as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Failed to load entries: $e');
      _entries = [];
    }
    _dayStartHour = (_prefs.getInt(_kDayStartHour) ?? 0).clamp(0, 23);
    _currencyCode = _prefs.getString(_kCurrency) ?? _defaultCurrency;
  }

  Future<void> _persist() async {
    await _prefs.setString(
      _kItems,
      jsonEncode(_items.map((i) => i.toJson()).toList()),
    );
    await _prefs.setString(
      _kEntries,
      jsonEncode(_entries.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> reset() async {
    _items = [];
    _entries = [];
    await _prefs.remove(_kItems);
    await _prefs.remove(_kEntries);
    notifyListeners();
  }
}