import 'package:collection/collection.dart';
import 'models.dart';

class DailyBucket {
  final DateTime date;
  final int count;
  final double spending;
  DailyBucket(this.date, this.count, this.spending);
}

class ItemTotal {
  final String itemId;
  final String name;
  final String category;
  final int count;
  final double spending;
  final DateTime? lastSeen;

  ItemTotal(
    this.itemId,
    this.name,
    this.category,
    this.count,
    this.spending, {
    this.lastSeen,
  });
}

class CategoryTotal {
  final String category;
  final int count;
  final double spending;

  CategoryTotal(this.category, this.count, this.spending);
}

class StatsSummary {
  final int totalCount;
  final double totalSpending;
  final List<DailyBucket> daily;
  final List<ItemTotal> topItems;
  final List<CategoryTotal> topCategories;
  final double averagePerDay;
  final double averageSpendPerDay;
  final int currentStreak;
  final int bestStreak;

  StatsSummary({
    required this.totalCount,
    required this.totalSpending,
    required this.daily,
    required this.topItems,
    required this.topCategories,
    required this.averagePerDay,
    required this.averageSpendPerDay,
    required this.currentStreak,
    required this.bestStreak,
  });
}

class StatsEngine {
  static StatsSummary compute({
    required List<Entry> entries,
    required List<Item> items,
    required int days,
    int startHour = 0,
  }) {
    DateTime logicalDay(DateTime dt) {
      final adjusted = dt.subtract(Duration(hours: startHour));
      return DateTime(adjusted.year, adjusted.month, adjusted.day);
    }

    final todayLogical = logicalDay(DateTime.now());
    final startLogical = todayLogical.subtract(Duration(days: days - 1));

    final windowed = entries
        .where((e) => !logicalDay(e.date).isBefore(startLogical))
        .toList();

    final itemMap = {for (final i in items) i.id: i};
    final grouped = groupBy(windowed, (Entry e) => logicalDay(e.date));

    // ---------- Daily buckets ----------
    final daily = <DailyBucket>[];
    for (var i = 0; i < days; i++) {
      final day = startLogical.add(Duration(days: i));
      final dayEntries = grouped[day] ?? const <Entry>[];
      daily.add(DailyBucket(
        day,
        dayEntries.length,
        dayEntries.fold(
          0.0,
          (s, e) => s + (e.pricePerUnit ?? 0) * e.quantity,
        ),
      ));
    }

    // ---------- Last seen (all-time) ----------
    final lastSeenByItem = <String, DateTime>{};
    for (final e in entries) {
      final prev = lastSeenByItem[e.itemId];
      if (prev == null || e.date.isAfter(prev)) {
        lastSeenByItem[e.itemId] = e.date;
      }
    }

    // ---------- Top items (windowed) ----------
    final byItem = groupBy(windowed, (Entry e) => e.itemId);
    final topItems = byItem.entries.map((e) {
      final list = e.value;
      final item = itemMap[e.key];
      return ItemTotal(
        e.key,
        item?.name ?? 'Unknown',
        item?.category ?? '',
        list.length,
        list.fold(
          0.0,
          (s, x) => s + (x.pricePerUnit ?? 0) * x.quantity,
        ),
        lastSeen: lastSeenByItem[e.key],
      );
    }).toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    // ---------- Top categories (windowed) ----------
    final byCategory = <String, List<Entry>>{};
    for (final e in windowed) {
      final category = itemMap[e.itemId]?.category ?? '';
      if (category.isEmpty) continue;
      byCategory.putIfAbsent(category, () => []).add(e);
    }
    final topCategories = byCategory.entries.map((e) {
      final list = e.value;
      return CategoryTotal(
        e.key,
        list.length,
        list.fold(
          0.0,
          (s, x) => s + (x.pricePerUnit ?? 0) * x.quantity,
        ),
      );
    }).toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    // ---------- Streaks (all-time) ----------
    final allDays = entries
        .map((e) => logicalDay(e.date))
        .toSet()
        .toList()
      ..sort();
    final allDaysSet = allDays.toSet();

    var bestStreak = 0;
    var run = 0;
    DateTime? prevDay;
    for (final d in allDays) {
      if (prevDay != null &&
          DateTime(prevDay.year, prevDay.month, prevDay.day + 1) == d) {
        run++;
      } else {
        run = 1;
      }
      if (run > bestStreak) bestStreak = run;
      prevDay = d;
    }

    var currentStreak = 0;
    if (allDaysSet.isNotEmpty) {
      var cursor = todayLogical;
      if (!allDaysSet.contains(cursor)) {
        cursor = cursor.subtract(const Duration(days: 1));
      }
      while (allDaysSet.contains(cursor)) {
        currentStreak++;
        cursor = cursor.subtract(const Duration(days: 1));
      }
    }

    // ---------- Totals ----------
    final totalCount = windowed.length;
    final totalSpending = windowed.fold(
      0.0,
      (s, e) => s + (e.pricePerUnit ?? 0) * e.quantity,
    );

    return StatsSummary(
      totalCount: totalCount,
      totalSpending: totalSpending,
      daily: daily,
      topItems: topItems.take(5).toList(),
      topCategories: topCategories.take(5).toList(),
      averagePerDay: totalCount / days,
      averageSpendPerDay: totalSpending / days,
      currentStreak: currentStreak,
      bestStreak: bestStreak,
    );
  }
}