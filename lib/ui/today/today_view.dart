import 'package:flutter/material.dart';
import '../../data/money.dart';
import '../../data/store.dart';
import '../../l10n/generated/app_localizations.dart';
import '../entries/entry_tile.dart';
import 'quick_add_row.dart';

class TodayView extends StatelessWidget {
  final Store store;

  const TodayView({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final items = store.items;
        final entries = store.entriesForDay(DateTime.now());
        final count = entries.length;
        final spending = entries.fold<double>(
          0,
          (s, e) => s + (e.pricePerUnit ?? 0) * e.quantity,
        );
        final locale = Localizations.localeOf(context).toString();

        return ListView(
          children: [
            QuickAddRow(store: store, items: items),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _Stat(label: l.todayEntries, value: '$count'),
                  _Stat(
                    label: l.todaySpent,
                    value: Money.format(
                      spending,
                      currencyCode: store.currencyCode,
                      locale: locale,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            if (entries.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(child: Text(l.todayEmpty)),
              )
            else
              ...entries.map((e) => EntryTile(store: store, entry: e)),
            const SizedBox(height: 88),
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