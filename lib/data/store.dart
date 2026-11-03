import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class Store extends ChangeNotifier {
  static const _kItems = 'items';
  static const _kEntries = 'entries';
  static const _kDayStartHour = 'dayStartHour';
  static const _kCurrency = 'currency';
  static const _kLanguageCode = 'languageCode';
  static const _kLastModified = 'lastModified';
  static const _kLastSynced = 'lastSynced';
  static const _kFilterTimeFrom = 'filterTimeFrom';
  static const _kFilterTimeTo = 'filterTimeTo';

  static const _defaultCurrency = 'EUR';
  static const _syncSchemaVersion = 1;

  static const _defaultFilterFromMinutes = 9 * 60;
  static const _defaultFilterToMinutes = 17 * 60;

  final SharedPreferences _prefs;
  List<Item> _items = [];
  List<Entry> _entries = [];
  int _dayStartHour = 0;
  String _currencyCode = _defaultCurrency;
  String _languageCode = '';
  DateTime? _lastModified;
  DateTime? _lastSynced;
  int _filterTimeFrom = _defaultFilterFromMinutes;
  int _filterTimeTo = _defaultFilterToMinutes;

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
  String get languageCode => _languageCode;
  DateTime? get lastModified => _lastModified;
  DateTime? get lastSynced => _lastSynced;
  int get filterTimeFromMinutes => _filterTimeFrom;
  int get filterTimeToMinutes => _filterTimeTo;

  bool get hasUnsyncedChanges {
    if (_lastSynced == null) {
      return _items.isNotEmpty || _entries.isNotEmpty;
    }
    final modified = _lastModified;
    if (modified == null) return false;
    return modified.isAfter(_lastSynced!);
  }

  // ---------- Settings ----------

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

  Future<void> setLanguageCode(String code) async {
    if (code == _languageCode) return;
    _languageCode = code;
    if (code.isEmpty) {
      await _prefs.remove(_kLanguageCode);
    } else {
      await _prefs.setString(_kLanguageCode, code);
    }
    notifyListeners();
  }

  Future<void> setFilterTimeRange(int fromMinutes, int toMinutes) async {
    final clampedFrom = fromMinutes.clamp(0, 23 * 60 + 59);
    final clampedTo = toMinutes.clamp(0, 23 * 60 + 59);
    if (clampedFrom == _filterTimeFrom && clampedTo == _filterTimeTo) return;
    _filterTimeFrom = clampedFrom;
    _filterTimeTo = clampedTo;
    await _prefs.setInt(_kFilterTimeFrom, clampedFrom);
    await _prefs.setInt(_kFilterTimeTo, clampedTo);
    notifyListeners();
  }

  // ---------- Queries ----------

  Item? itemById(String id) {
    for (final item in _items) {
      if (item.id == id) return item;
    }
    return null;
  }

  /// The logical day that a given timestamp belongs to.
  DateTime logicalDay(DateTime dt) {
    final adjusted = dt.subtract(Duration(hours: _dayStartHour));
    return DateTime(adjusted.year, adjusted.month, adjusted.day);
  }

  /// The half-open interval of the logical day containing [anchor].
  /// Used when you have a moment and want to know which day it falls in.
  (DateTime, DateTime) logicalDayRange(DateTime anchor) {
    final adjusted = anchor.subtract(Duration(hours: _dayStartHour));
    final start = DateTime(adjusted.year, adjusted.month, adjusted.day)
        .add(Duration(hours: _dayStartHour));
    final end = start.add(const Duration(days: 1));
    return (start, end);
  }

  /// The half-open interval of the calendar date [date], adjusted by
  /// [dayStartHour]. Used when the user has picked a date label (e.g.
  /// "Nov 3" from a date picker) and you need the range that label
  /// actually covers.
  ///
  /// With dayStartHour=0, "Nov 3" → [Nov 3 00:00, Nov 4 00:00).
  /// With dayStartHour=4, "Nov 3" → [Nov 3 04:00, Nov 4 04:00).
  (DateTime, DateTime) calendarDayRange(DateTime date) {
    final start = DateTime(date.year, date.month, date.day)
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

  // ---------- Mutations ----------

  Future<void> saveItem(Item item) async {
    final i = _items.indexWhere((x) => x.id == item.id);
    if (i >= 0) {
      _items[i] = item;
    } else {
      _items.add(item);
    }
    _touch();
    await _persist();
    notifyListeners();
  }

  Future<void> deleteItem(String id) async {
    _items.removeWhere((i) => i.id == id);
    _entries.removeWhere((e) => e.itemId == id);
    _touch();
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
    _touch();
    await _persist();
    notifyListeners();
  }

  Future<void> deleteEntry(String id) async {
    _entries.removeWhere((e) => e.id == id);
    _touch();
    await _persist();
    notifyListeners();
  }

  Future<void> reset() async {
    _items = [];
    _entries = [];
    _touch();
    await _prefs.remove(_kItems);
    await _prefs.remove(_kEntries);
    await _prefs.setString(
      _kLastModified,
      _lastModified!.toIso8601String(),
    );
    notifyListeners();
  }

  // ---------- Sync ----------

  String toSyncJson() {
    return jsonEncode({
      'schemaVersion': _syncSchemaVersion,
      'lastModified':
          (_lastModified ?? DateTime.now().toUtc()).toUtc().toIso8601String(),
      'items': _items.map((i) => i.toJson()).toList(),
      'entries': _entries.map((e) => e.toJson()).toList(),
    });
  }

  Future<void> mergeFromSync(String jsonString, {bool force = false}) async {
    final data = jsonDecode(jsonString) as Map<String, dynamic>;

    final schemaVersion = data['schemaVersion'] as int? ?? 0;
    if (schemaVersion != _syncSchemaVersion) {
      throw Exception('Unsupported backup schema version: $schemaVersion');
    }

    final remoteModified =
        DateTime.tryParse(data['lastModified'] as String? ?? '')?.toUtc();
    if (remoteModified == null) {
      throw Exception('Backup is missing a lastModified timestamp');
    }

    if (!force &&
        _lastModified != null &&
        _lastModified!.toUtc().isAfter(remoteModified)) {
      debugPrint('Local data is newer; skipping merge');
      return;
    }

    _items = (data['items'] as List)
        .map((j) => Item.fromJson(j as Map<String, dynamic>))
        .toList();
    _entries = (data['entries'] as List)
        .map((j) => Entry.fromJson(j as Map<String, dynamic>))
        .toList();
    _lastModified = remoteModified;

    await _persist();
    await _prefs.setString(
      _kLastModified,
      _lastModified!.toIso8601String(),
    );
    notifyListeners();
  }

  Future<void> markSynced() async {
    _lastSynced = DateTime.now().toUtc();
    await _prefs.setString(_kLastSynced, _lastSynced!.toIso8601String());
    notifyListeners();
  }

  // ---------- Internal ----------

  void _touch() => _lastModified = DateTime.now().toUtc();

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
    _languageCode = _prefs.getString(_kLanguageCode) ?? '';
    final lastModStr = _prefs.getString(_kLastModified);
    if (lastModStr != null) {
      _lastModified = DateTime.tryParse(lastModStr)?.toUtc();
    }
    final lastSyncStr = _prefs.getString(_kLastSynced);
    if (lastSyncStr != null) {
      _lastSynced = DateTime.tryParse(lastSyncStr)?.toUtc();
    }
    _filterTimeFrom = _prefs.getInt(_kFilterTimeFrom)
            ?.clamp(0, 23 * 60 + 59) ??
        _defaultFilterFromMinutes;
    _filterTimeTo = _prefs.getInt(_kFilterTimeTo)
            ?.clamp(0, 23 * 60 + 59) ??
        _defaultFilterToMinutes;
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
}