import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
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
                  title: Text(t.name),
                  trailing: Text(
                    '${t.count} · ${Money.format(t.spending, currencyCode: code, locale: locale)}',
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;

  const _Stat({required this.label, required this.value});

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
      ],
    );
  }
}