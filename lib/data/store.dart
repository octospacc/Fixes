import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

enum SyncDirection { upload, download }

class EntryPreset {
  final String note;
  final double? price;
  final int count;

  const EntryPreset({
    required this.note,
    required this.price,
    required this.count,
  });
}

class Store extends ChangeNotifier {
  static const _kItems = 'items';
  static const _kEntries = 'entries';
  static const _kDayStartHour = 'dayStartHour';
  static const _kCurrency = 'currency';
  static const _kLanguageCode = 'languageCode';
  static const _kLastModified = 'lastModified';
  static const _kLastSynced = 'lastSynced';
  static const _kLastSyncDirection = 'lastSyncDirection';
  static const _kLastRemoteRev = 'lastRemoteRev';
  static const _kAutoSync = 'autoSync';
  static const _kFilterTimeFrom = 'filterTimeFrom';
  static const _kFilterTimeTo = 'filterTimeTo';
  static const _kFilterPriceMin = 'filterPriceMin';
  static const _kFilterPriceMax = 'filterPriceMax';

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
  SyncDirection? _lastSyncDirection;
  String? _lastRemoteRev;
  bool _autoSync = true;
  bool _syncing = false;
  bool _dropboxConnected = false;
  int _filterTimeFrom = _defaultFilterFromMinutes;
  int _filterTimeTo = _defaultFilterToMinutes;
  String _filterPriceMin = '';
  String _filterPriceMax = '';

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
  SyncDirection? get lastSyncDirection => _lastSyncDirection;
  String? get lastRemoteRev => _lastRemoteRev;
  bool get autoSync => _autoSync;
  bool get syncing => _syncing;
  bool get dropboxConnected => _dropboxConnected;
  int get filterTimeFromMinutes => _filterTimeFrom;
  int get filterTimeToMinutes => _filterTimeTo;
  String get filterPriceMin => _filterPriceMin;
  String get filterPriceMax => _filterPriceMax;

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

  Future<void> setAutoSync(bool value) async {
    if (value == _autoSync) return;
    _autoSync = value;
    await _prefs.setBool(_kAutoSync, value);
    notifyListeners();
  }

  /// Transient: true while a Dropbox upload or download is running.
  /// Drives the app-bar spinner. Not persisted.
  void setSyncing(bool value) {
    if (value == _syncing) return;
    _syncing = value;
    notifyListeners();
  }

  /// Transient: reflects the current Dropbox auth state. Set at launch
  /// from `DropboxSync.isSignedIn()` and updated by Settings when the
  /// user connects or disconnects. Not persisted.
  void setDropboxConnected(bool value) {
    if (value == _dropboxConnected) return;
    _dropboxConnected = value;
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

  Future<void> setFilterPriceRange(String min, String max) async {
    if (min == _filterPriceMin && max == _filterPriceMax) return;
    _filterPriceMin = min;
    _filterPriceMax = max;
    if (min.isEmpty) {
      await _prefs.remove(_kFilterPriceMin);
    } else {
      await _prefs.setString(_kFilterPriceMin, min);
    }
    if (max.isEmpty) {
      await _prefs.remove(_kFilterPriceMax);
    } else {
      await _prefs.setString(_kFilterPriceMax, max);
    }
  }

  // ---------- Queries ----------

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
      item.sortOrder = _items[i].sortOrder;
      _items[i] = item;
    } else {
      item.sortOrder = _items.isEmpty
          ? 0
          : _items
                  .map((x) => x.sortOrder)
                  .reduce((a, b) => a > b ? a : b) +
              1;
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
    await _prefs.remove(_kItems);
    await _prefs.remove(_kEntries);
    notifyListeners();
  }

  Future<void> reorderItems(List<Item> newOrder) async {
    for (var i = 0; i < newOrder.length; i++) {
      newOrder[i].sortOrder = i;
    }
    _items = newOrder;
    _touch();
    // notifyListeners fires before the await so ReorderableListView's
    // post-drop animation sees the updated order. Without this, the
    // dropped row snaps back briefly.
    notifyListeners();
    await _persist();
  }

  /// Reorders items so that the most-used items come first, then the
  /// lesser-used ones, preserving the current order as the final
  /// tiebreaker.
  ///
  /// Ranking key, in priority order:
  ///   1. entries in the last 30 days  (descending) — current habit
  ///   2. all-time entry count          (descending) — historical weight
  ///   3. last-used timestamp           (descending) — recency
  ///   4. current sortOrder             (ascending)  — stable fallback
  ///
  /// Produces a new manual order: after this call, subsequent drags
  /// start from the sorted arrangement, and no further sorting happens
  /// automatically.
  Future<void> sortItemsByUsage() async {
    if (_items.length < 2) return;

    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(days: 30));

    final recentCount = <String, int>{};
    final totalCount = <String, int>{};
    final lastUsed = <String, DateTime>{};

    for (final e in _entries) {
      totalCount[e.itemId] = (totalCount[e.itemId] ?? 0) + 1;
      if (e.date.isAfter(cutoff)) {
        recentCount[e.itemId] = (recentCount[e.itemId] ?? 0) + 1;
      }
      final prev = lastUsed[e.itemId];
      if (prev == null || e.date.isAfter(prev)) {
        lastUsed[e.itemId] = e.date;
      }
    }

    final sorted = List<Item>.from(_items);
    sorted.sort((a, b) {
      final ra = recentCount[a.id] ?? 0;
      final rb = recentCount[b.id] ?? 0;
      if (ra != rb) return rb.compareTo(ra);

      final ta = totalCount[a.id] ?? 0;
      final tb = totalCount[b.id] ?? 0;
      if (ta != tb) return tb.compareTo(ta);

      final la = lastUsed[a.id];
      final lb = lastUsed[b.id];
      if (la != null && lb != null && la != lb) {
        return lb.compareTo(la);
      }
      if (la != null && lb == null) return -1;
      if (la == null && lb != null) return 1;

      return a.sortOrder.compareTo(b.sortOrder);
    });

    for (var i = 0; i < sorted.length; i++) {
      sorted[i].sortOrder = i;
    }
    _items = sorted;
    _touch();
    notifyListeners();
    await _persist();
  }

  /// Ensures items are sorted by sortOrder and the values are contiguous
  /// 0..n-1. Handles three cases:
  ///   1. Old data (all sortOrder==0): assign 0..n-1 in current JSON order.
  ///   2. Fresh data: already contiguous, no-op.
  ///   3. Mixed (some 0, some non-0, possible duplicates): sort with the
  ///      original list index as tiebreaker, then renumber.
  void _ensureSortOrder() {
    if (_items.isEmpty) return;
    final indexed = _items.asMap().entries.toList();
    indexed.sort((a, b) {
      final cmp = a.value.sortOrder.compareTo(b.value.sortOrder);
      if (cmp != 0) return cmp;
      return a.key.compareTo(b.key);
    });
    _items = indexed.map((e) => e.value).toList();
    for (var i = 0; i < _items.length; i++) {
      _items[i].sortOrder = i;
    }
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

  Future<bool> mergeFromSync(String jsonString, {bool force = false}) async {
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
      return false;
    }

    _items = (data['items'] as List)
        .map((j) => Item.fromJson(j as Map<String, dynamic>))
        .toList();
    _ensureSortOrder();
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
    return true;
  }

  Future<void> markSynced(SyncDirection direction) async {
    _lastSynced = DateTime.now().toUtc();
    _lastSyncDirection = direction;
    await _prefs.setString(_kLastSynced, _lastSynced!.toIso8601String());
    await _prefs.setString(_kLastSyncDirection, direction.name);
    notifyListeners();
  }

  Future<void> setLastRemoteRev(String? rev) async {
    if (rev == _lastRemoteRev) return;
    _lastRemoteRev = rev;
    if (rev == null) {
      await _prefs.remove(_kLastRemoteRev);
    } else {
      await _prefs.setString(_kLastRemoteRev, rev);
    }
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
    _ensureSortOrder();
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
    final dirStr = _prefs.getString(_kLastSyncDirection);
    if (dirStr != null) {
      _lastSyncDirection = SyncDirection.values.firstWhere(
        (d) => d.name == dirStr,
        orElse: () => SyncDirection.upload,
      );
    }
    _lastRemoteRev = _prefs.getString(_kLastRemoteRev);
    _autoSync = _prefs.getBool(_kAutoSync) ?? true;
    _filterTimeFrom = _prefs.getInt(_kFilterTimeFrom)
            ?.clamp(0, 23 * 60 + 59) ??
        _defaultFilterFromMinutes;
    _filterTimeTo = _prefs.getInt(_kFilterTimeTo)
            ?.clamp(0, 23 * 60 + 59) ??
        _defaultFilterToMinutes;
    _filterPriceMin = _prefs.getString(_kFilterPriceMin) ?? '';
    _filterPriceMax = _prefs.getString(_kFilterPriceMax) ?? '';
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

  /// Returns up to [limit] note suggestions drawn from past entries,
  /// ranked by relevance to the given [itemId] and [category].
  ///
  /// If [prefix] is non-empty, only notes that start with it
  /// (case-insensitive) are considered, and exact matches are hidden
  /// because the user has already typed the whole thing.
  ///
  /// No absolute score threshold is applied: every distinct past note is
  /// a candidate, ranked by item match, category match, recency, and
  /// frequency. The [limit] alone bounds the list size, which keeps the
  /// suggestion chips from overflowing the screen without hiding notes
  /// the user actually wrote.
  List<String> suggestNotes({
    String? itemId,
    String? category,
    String prefix = '',
    int limit = 10,
  }) {
    if (_entries.isEmpty) return const [];

    final p = prefix.trim().toLowerCase();

    String? targetCategory = category;
    if ((targetCategory == null || targetCategory.isEmpty) &&
        itemId != null) {
      targetCategory = itemById(itemId)?.category;
    }

    final now = DateTime.now();
    final score = <String, double>{};

    for (final entry in _entries) {
      final note = entry.note.trim();
      if (note.isEmpty) continue;

      if (p.isNotEmpty) {
        final lower = note.toLowerCase();
        if (!lower.startsWith(p)) continue;
        if (lower == p) continue;
      }

      final entryItem = itemById(entry.itemId);
      final entryCategory = entryItem?.category ?? '';

      double entryScore = 1.0;
      if (itemId != null && entry.itemId == itemId) entryScore += 50;
      if (targetCategory != null &&
          targetCategory.isNotEmpty &&
          entryCategory == targetCategory) {
        entryScore += 15;
      }

      final ageDays = now.difference(entry.date).inHours / 24.0;
      entryScore += 3.0 / (1.0 + ageDays / 30.0);

      score[note] = (score[note] ?? 0) + entryScore;
    }

    final ranked = score.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return ranked.take(limit).map((e) => e.key).toList();
  }

  /// Returns up to [limit] prices to suggest for [itemId], ordered by
  /// how often they've been used with this item. The item's
  /// `defaultPrice` is included even if never used, ranked below any
  /// prices that have actual history.
  ///
  /// Ties are broken in favour of the defaultPrice, then by numeric
  /// value. Returns an empty list when the item has neither a default
  /// price nor any past priced entries.
  List<double> suggestPricesForItem(String itemId, {int limit = 4}) {
    final item = itemById(itemId);
    final defaultPrice = item?.defaultPrice;

    final counts = <double, int>{};
    for (final e in _entries) {
      if (e.itemId != itemId) continue;
      final p = e.pricePerUnit;
      if (p == null) continue;
      counts[p] = (counts[p] ?? 0) + 1;
    }

    if (defaultPrice != null && !counts.containsKey(defaultPrice)) {
      // Include the default so the user can still pick it, but at the
      // bottom of the list — its zero count sorts below any real history.
      counts[defaultPrice] = 0;
    }

    final sorted = counts.entries.toList()
      ..sort((a, b) {
        final cmp = b.value.compareTo(a.value);
        if (cmp != 0) return cmp;
        if (defaultPrice == a.key) return -1;
        if (defaultPrice == b.key) return 1;
        return a.key.compareTo(b.key);
      });

    return sorted.take(limit).map((e) => e.key).toList();
  }

  /// Returns up to [limit] (note, price) combinations for [itemId],
  /// ordered by how often they've appeared together in that item's
  /// history. Fully blank entries — no note, no price — are skipped
  /// because they carry no useful information as a preset.
  ///
  /// Two entries with the same note but different prices produce two
  /// separate presets, e.g. "Macchinetta · €0.70" and
  /// "Macchinetta · €0.50", because they represent distinct habits.
  List<EntryPreset> suggestPresetsForItem(String itemId, {int limit = 6}) {
    final counts = <String, int>{};
    final bases = <String, EntryPreset>{};

    for (final e in _entries) {
      if (e.itemId != itemId) continue;
      final note = e.note.trim();
      final price = e.pricePerUnit;
      if (note.isEmpty && price == null) continue;

      final key = '$note|${price ?? 'null'}';
      counts[key] = (counts[key] ?? 0) + 1;
      bases.putIfAbsent(
        key,
        () => EntryPreset(note: note, price: price, count: 0),
      );
    }

    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(limit).map((e) {
      final base = bases[e.key]!;
      return EntryPreset(
        note: base.note,
        price: base.price,
        count: e.value,
      );
    }).toList();
  }
}