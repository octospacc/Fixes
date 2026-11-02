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
  final int count;
  final double spending;
  ItemTotal(this.itemId, this.name, this.count, this.spending);
}

class StatsSummary {
  final int totalCount;
  final double totalSpending;
  final List<DailyBucket> daily;
  final List<ItemTotal> topItems;

  StatsSummary({
    required this.totalCount,
    required this.totalSpending,
    required this.daily,
    required this.topItems,
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
    final startLogical =
        todayLogical.subtract(Duration(days: days - 1));

    final filtered = entries
        .where((e) => !logicalDay(e.date).isBefore(startLogical))
        .toList();

    final itemMap = {for (final i in items) i.id: i};
    final grouped = groupBy(filtered, (Entry e) => logicalDay(e.date));

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

    final byItem = groupBy(filtered, (Entry e) => e.itemId);
    final top = byItem.entries.map((e) {
      final list = e.value;
      final name = itemMap[e.key]?.name ?? 'Unknown';
      return ItemTotal(
        e.key,
        name,
        list.length,
        list.fold(
          0.0,
          (s, x) => s + (x.pricePerUnit ?? 0) * x.quantity,
        ),
      );
    }).toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    return StatsSummary(
      totalCount: filtered.length,
      totalSpending: filtered.fold(
        0.0,
        (s, e) => s + (e.pricePerUnit ?? 0) * e.quantity,
      ),
      daily: daily,
      topItems: top.take(5).toList(),
    );
  }
}