import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/history_filter.dart';
import '../../data/models.dart';
import '../../data/money.dart';
import '../../data/store.dart';
import '../../l10n/generated/app_localizations.dart';
import '../entries/entry_tile.dart';
import 'history_filter_sheet.dart';

class HistoryView extends StatefulWidget {
  final Store store;

  const HistoryView({super.key, required this.store});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  String _query = '';
  HistoryFilter _filter = HistoryFilter.empty;

  bool _matchesSearch(Entry e, Item? item) {
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    final name = item?.name.toLowerCase() ?? '';
    final category = item?.category.toLowerCase() ?? '';
    final note = e.note.toLowerCase();
    return name.contains(q) || category.contains(q) || note.contains(q);
  }

  bool _passesFilter(Entry e) {
    if (_filter.dateMode == DateFilterMode.specificDay &&
        _filter.specificDay != null) {
      final (start, end) =
          widget.store.calendarDayRange(_filter.specificDay!);
      if (e.date.isBefore(start) || !e.date.isBefore(end)) return false;
    } else if (_filter.dateMode == DateFilterMode.range &&
        _filter.dateRange != null) {
      final (start, _) =
          widget.store.calendarDayRange(_filter.dateRange!.start);
      final (_, end) =
          widget.store.calendarDayRange(_filter.dateRange!.end);
      if (e.date.isBefore(start) || !e.date.isBefore(end)) return false;
    }
    if (_filter.timeRange != null && !_filter.timeRange!.matches(e.date)) {
      return false;
    }
    if (!_filter.priceFilter.matches(e.pricePerUnit)) return false;
    return true;
  }

  Future<void> _openFilterSheet() async {
    final result =
        await showHistoryFilterSheet(context, widget.store, _filter);
    if (result != null && mounted) {
      setState(() => _filter = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final itemMap = {for (final i in widget.store.items) i.id: i};
        final all = widget.store.entriesSortedByDate;

        final filtered = all.where((e) {
          return _matchesSearch(e, itemMap[e.itemId]) && _passesFilter(e);
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
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: l.historySearchHint,
                        border: const OutlineInputBorder(),
                        suffixIcon: _query.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () =>
                                    setState(() => _query = ''),
                              ),
                      ),
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: l.historyFilterTitle,
                    icon: Icon(
                      Icons.tune,
                      color: _filter.isActive
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    onPressed: _openFilterSheet,
                  ),
                ],
              ),
            ),
            if (_filter.isActive) _buildChips(context, l),
            Expanded(
              child: dates.isEmpty
                  ? Center(
                      child: Text(
                        all.isEmpty
                            ? l.historyEmpty
                            : l.historyFilterNoResults,
                      ),
                    )
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

  Widget _buildChips(BuildContext context, AppLocalizations l) {
    final locale = Localizations.localeOf(context).toString();
    final dateFormat = DateFormat.yMd(locale);

    final chips = <Widget>[];

    // Date chip
    if (_filter.dateMode == DateFilterMode.specificDay &&
        _filter.specificDay != null) {
      chips.add(InputChip(
        label: Text(_dayLabel(_filter.specificDay!, context, l)),
        onDeleted: () => setState(() {
          _filter = HistoryFilter(
            timeRange: _filter.timeRange,
            priceFilter: _filter.priceFilter,
          );
        }),
        deleteIcon: const Icon(Icons.close, size: 16),
      ));
    } else if (_filter.dateMode == DateFilterMode.range &&
        _filter.dateRange != null) {
      chips.add(InputChip(
        label: Text(
          '${dateFormat.format(_filter.dateRange!.start)} – '
          '${dateFormat.format(_filter.dateRange!.end)}',
        ),
        onDeleted: () => setState(() {
          _filter = HistoryFilter(
            timeRange: _filter.timeRange,
            priceFilter: _filter.priceFilter,
          );
        }),
        deleteIcon: const Icon(Icons.close, size: 16),
      ));
    }

    // Time chip
    if (_filter.timeRange != null) {
      chips.add(InputChip(
        label: Text(
          '${_filter.timeRange!.start.format(context)} – '
          '${_filter.timeRange!.end.format(context)}',
        ),
        onDeleted: () => setState(() {
          _filter = HistoryFilter(
            dateMode: _filter.dateMode,
            specificDay: _filter.specificDay,
            dateRange: _filter.dateRange,
            priceFilter: _filter.priceFilter,
          );
        }),
        deleteIcon: const Icon(Icons.close, size: 16),
      ));
    }

    // Price chip
    if (_filter.priceFilter.isActive) {
      chips.add(InputChip(
        label: Text(_priceChipLabel(context, l)),
        onDeleted: () => setState(() {
          _filter = HistoryFilter(
            dateMode: _filter.dateMode,
            specificDay: _filter.specificDay,
            dateRange: _filter.dateRange,
            timeRange: _filter.timeRange,
          );
        }),
        deleteIcon: const Icon(Icons.close, size: 16),
      ));
    }

    chips.add(TextButton(
      onPressed: () => setState(() => _filter = HistoryFilter.empty),
      child: Text(l.historyFilterClearAll),
    ));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Row(
        children: [
          for (var i = 0; i < chips.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            chips[i],
          ],
        ],
      ),
    );
  }

  String _priceChipLabel(BuildContext context, AppLocalizations l) {
    final pf = _filter.priceFilter;
    switch (pf.mode) {
      case PriceFilterMode.hasPrice:
        return l.historyFilterPriceHas;
      case PriceFilterMode.noPrice:
        return l.historyFilterPriceNo;
      case PriceFilterMode.inRange:
        final locale = Localizations.localeOf(context).toString();
        String fmt(double v) => Money.format(
              v,
              currencyCode: widget.store.currencyCode,
              locale: locale,
            );
        if (pf.min != null && pf.max != null) {
          return '${fmt(pf.min!)} – ${fmt(pf.max!)}';
        } else if (pf.min != null) {
          return '≥ ${fmt(pf.min!)}';
        } else if (pf.max != null) {
          return '≤ ${fmt(pf.max!)}';
        }
        return l.historyFilterPriceAny;
      case PriceFilterMode.any:
        return l.historyFilterPriceAny;
    }
  }

  String _dayLabel(DateTime day, BuildContext context, AppLocalizations l) {
    final today = widget.store.logicalDay(DateTime.now());
    if (_sameDay(day, today)) return l.historyToday;
    final yesterday = today.subtract(const Duration(days: 1));
    if (_sameDay(day, yesterday)) return l.historyYesterday;
    return DateFormat.yMd(Localizations.localeOf(context).toString())
        .format(day);
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