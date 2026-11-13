import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../data/category_icons.dart';
import '../../data/money.dart';
import '../../data/stats_engine.dart';
import '../../data/store.dart';
import '../../l10n/generated/app_localizations.dart';

class StatsView extends StatefulWidget {
  final Store store;

  const StatsView({super.key, required this.store});

  @override
  State<StatsView> createState() => _StatsViewState();
}

class _StatsViewState extends State<StatsView> {
  int _days = 30;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final summary = StatsEngine.compute(
          entries: widget.store.entries,
          items: widget.store.items,
          days: _days,
          startHour: widget.store.dayStartHour,
        );

        final maxCount = summary.daily
            .map((d) => d.count)
            .fold<int>(0, (a, b) => a > b ? a : b);
        final chartMax = (maxCount < 4 ? 4 : maxCount + 1).toDouble();
        final locale = Localizations.localeOf(context).toString();
        final code = widget.store.currencyCode;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<int>(
              segments: [
                ButtonSegment(value: 7, label: Text(l.statsRange7)),
                ButtonSegment(value: 30, label: Text(l.statsRange30)),
                ButtonSegment(value: 90, label: Text(l.statsRange90)),
              ],
              selected: {_days},
              onSelectionChanged: (s) => setState(() => _days = s.first),
            ),
            const SizedBox(height: 24),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Stat(
                  label: l.statsTotalEntries,
                  value: '${summary.totalCount}',
                ),
                _Stat(
                  label: l.statsTotalSpent,
                  value: Money.format(
                    summary.totalSpending,
                    currencyCode: code,
                    locale: locale,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Stat(
                  label: l.statsCurrentStreak,
                  value: '${summary.currentStreak}',
                  subtitle: l.statsBestStreak(summary.bestStreak),
                ),
                _Stat(
                  label: l.statsAveragePerDay,
                  value: summary.averagePerDay.toStringAsFixed(1),
                  subtitle: l.statsAverageSpendSubtitle(
                    Money.format(
                      summary.averageSpendPerDay,
                      currencyCode: code,
                      locale: locale,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Text(
              l.statsDailyCount,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  minY: 0,
                  maxY: chartMax,
                  barGroups: summary.daily.asMap().entries.map((e) {
                    return BarChartGroupData(
                      x: e.key,
                      barRods: [
                        BarChartRodData(
                          toY: e.value.count.toDouble(),
                          width: 6,
                          borderRadius: BorderRadius.circular(2),
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    );
                  }).toList(),
                  titlesData: const FlTitlesData(show: false),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barTouchData: BarTouchData(enabled: false),
                ),
              ),
            ),
            const SizedBox(height: 24),

            Text(
              l.statsTopItems,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            if (summary.topItems.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(child: Text(l.statsEmpty)),
              )
            else
              ...summary.topItems.map(
                (t) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(iconForCategory(t.category)),
                  title: Text(t.name),
                  subtitle: Text(
                    '${_lastSeenText(t.lastSeen, l)} · '
                    '${l.statsItemDailyRate(_fmtPerDay(t.totalQuantity / _days))}',
                  ),
                  trailing: Text(_trailingText(t, code, locale)),
                ),
              ),
            const SizedBox(height: 24),

            Text(
              l.statsTopCategories,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            if (summary.topCategories.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(child: Text(l.statsEmpty)),
              )
            else
              ...summary.topCategories.map(
                (c) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(iconForCategory(c.category)),
                  title: Text(c.category),
                  trailing: Text(
                    '${c.count} · ${Money.format(c.spending, currencyCode: code, locale: locale)}',
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  String _lastSeenText(DateTime? lastSeen, AppLocalizations l) {
    if (lastSeen == null) return '';
    final lastLogical = widget.store.logicalDay(lastSeen);
    final todayLogical = widget.store.logicalDay(DateTime.now());
    final days = todayLogical.difference(lastLogical).inDays;
    if (days <= 0) return l.statsLastSeenToday;
    if (days == 1) return l.statsLastSeenYesterday;
    return l.statsLastSeenDaysAgo(days);
  }

  String _fmtPerDay(double v) {
    if (v < 0.05) return '<0.1';
    if (v >= 10) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }

  String _fmtQty(double q) {
    if (q == q.roundToDouble()) return q.toInt().toString();
    // Fallback for fractional quantities. Trim trailing zeros.
    return q.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
  }

  String _trailingText(ItemTotal t, String code, String locale) {
    final spend = Money.format(
      t.spending,
      currencyCode: code,
      locale: locale,
    );
    final qtyIsWhole = t.totalQuantity == t.totalQuantity.roundToDouble();
    final qtySameAsEntries =
        qtyIsWhole && t.totalQuantity.toInt() == t.count;
    if (qtySameAsEntries) {
      return '${t.count} · $spend';
    }
    return '${t.count} · ${_fmtQty(t.totalQuantity)} · $spend';
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;

  const _Stat({
    required this.label,
    required this.value,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(label),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}