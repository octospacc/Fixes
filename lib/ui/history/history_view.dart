import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models.dart';
import '../../data/store.dart';
import '../../l10n/generated/app_localizations.dart';
import '../entries/entry_tile.dart';

class HistoryView extends StatefulWidget {
  final Store store;

  const HistoryView({super.key, required this.store});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final itemMap = {for (final i in widget.store.items) i.id: i};
        final all = widget.store.entriesSortedByDate;
        final filtered = _query.isEmpty
            ? all
            : all.where((e) {
                final name = itemMap[e.itemId]?.name ?? '';
                return name.toLowerCase().contains(_query.toLowerCase());
              }).toList();

        final grouped = groupBy(
          filtered,
          (Entry e) => widget.store.logicalDay(e.date),
        );
        final dates = grouped.keys.toList()
          ..sort((a, b) => b.compareTo(a));

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: l.historySearchHint,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            Expanded(
              child: dates.isEmpty
                  ? Center(child: Text(l.historyEmpty))
                  : ListView.builder(
                      itemCount: dates.length,
                      itemBuilder: (context, i) {
                        final date = dates[i];
                        final dayEntries = grouped[date]!;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 12, 16, 4),
                              child: Text(
                                _dateHeader(date, context, l),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            ...dayEntries.map((e) => EntryTile(
                                  store: widget.store,
                                  entry: e,
                                )),
                            const Divider(),
                          ],
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  String _dateHeader(
    DateTime d,
    BuildContext context,
    AppLocalizations l,
  ) {
    final today = widget.store.logicalDay(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));
    if (_sameDay(d, today)) return l.historyToday;
    if (_sameDay(d, yesterday)) return l.historyYesterday;
    return DateFormat.yMd(
      Localizations.localeOf(context).toString(),
    ).format(d);
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}