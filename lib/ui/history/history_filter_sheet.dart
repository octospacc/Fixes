import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/history_filter.dart';
import '../../data/money.dart';
import '../../data/store.dart';
import '../../l10n/generated/app_localizations.dart';

Future<HistoryFilter?> showHistoryFilterSheet(
  BuildContext context,
  Store store,
  HistoryFilter initial,
) {
  return showModalBottomSheet<HistoryFilter>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _HistoryFilterSheet(store: store, initial: initial),
  );
}

class _HistoryFilterSheet extends StatefulWidget {
  final Store store;
  final HistoryFilter initial;

  const _HistoryFilterSheet({required this.store, required this.initial});

  @override
  State<_HistoryFilterSheet> createState() => _HistoryFilterSheetState();
}

class _HistoryFilterSheetState extends State<_HistoryFilterSheet> {
  late DateFilterMode _dateMode;
  late DateTime? _specificDay;
  late DateTimeRange? _dateRange;
  late bool _timeEnabled;
  late TimeOfDay _timeFrom;
  late TimeOfDay _timeTo;
  late PriceFilterMode _priceMode;
  late Set<int> _weekdays;
  late final TextEditingController _priceMinCtrl;
  late final TextEditingController _priceMaxCtrl;

  @override
  void initState() {
    super.initState();
    _dateMode = widget.initial.dateMode;
    _specificDay = widget.initial.specificDay;
    _dateRange = widget.initial.dateRange;
    _timeEnabled = widget.initial.timeRange != null;

    if (widget.initial.timeRange != null) {
      _timeFrom = widget.initial.timeRange!.start;
      _timeTo = widget.initial.timeRange!.end;
    } else {
      final from = widget.store.filterTimeFromMinutes;
      final to = widget.store.filterTimeToMinutes;
      _timeFrom = TimeOfDay(hour: from ~/ 60, minute: from % 60);
      _timeTo = TimeOfDay(hour: to ~/ 60, minute: to % 60);
    }

    _priceMode = widget.initial.priceFilter.mode;
    _priceMinCtrl =
        TextEditingController(text: widget.store.filterPriceMin);
    _priceMaxCtrl =
        TextEditingController(text: widget.store.filterPriceMax);
    _weekdays = Set<int>.from(widget.initial.weekdays);

    if (_dateMode == DateFilterMode.specificDay && _specificDay == null) {
      _specificDay = _today();
    }
    if (_dateMode == DateFilterMode.range && _dateRange == null) {
      final today = _today();
      _dateRange = DateTimeRange(
        start: today.subtract(const Duration(days: 6)),
        end: today,
      );
    }
  }

  @override
  void dispose() {
    _priceMinCtrl.dispose();
    _priceMaxCtrl.dispose();
    super.dispose();
  }

  DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  void _persistPriceRange() {
    widget.store.setFilterPriceRange(
      _priceMinCtrl.text,
      _priceMaxCtrl.text,
    );
  }

  HistoryFilter _buildFilter() {
    PriceFilter priceFilter;
    if (_priceMode == PriceFilterMode.inRange) {
      double? min = double.tryParse(_priceMinCtrl.text.trim());
      double? max = double.tryParse(_priceMaxCtrl.text.trim());
      if (min != null && max != null && min > max) {
        final t = min;
        min = max;
        max = t;
      }
      if (min == null && max == null) {
        priceFilter = const PriceFilter();
      } else {
        priceFilter = PriceFilter(
          mode: PriceFilterMode.inRange,
          min: min,
          max: max,
        );
      }
    } else {
      priceFilter = PriceFilter(mode: _priceMode);
    }

    return HistoryFilter(
      dateMode: _dateMode,
      specificDay:
          _dateMode == DateFilterMode.specificDay ? _specificDay : null,
      dateRange: _dateMode == DateFilterMode.range ? _dateRange : null,
      timeRange: _timeEnabled
          ? TimeRange(start: _timeFrom, end: _timeTo)
          : null,
      priceFilter: priceFilter,
      weekdays: Set.unmodifiable(_weekdays),
    );
  }

  Future<void> _pickSpecificDay() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _specificDay ?? _today(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _specificDay = picked);
  }

  Future<void> _pickDateRange() async {
    final today = _today();
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _dateRange ??
          DateTimeRange(
            start: today.subtract(const Duration(days: 6)),
            end: today,
          ),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _dateRange = picked);
  }

  Future<void> _pickTimeFrom() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _timeFrom,
    );
    if (picked != null) {
      setState(() => _timeFrom = picked);
      await widget.store.setFilterTimeRange(
        picked.hour * 60 + picked.minute,
        _timeTo.hour * 60 + _timeTo.minute,
      );
    }
  }

  Future<void> _pickTimeTo() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _timeTo,
    );
    if (picked != null) {
      setState(() => _timeTo = picked);
      await widget.store.setFilterTimeRange(
        _timeFrom.hour * 60 + _timeFrom.minute,
        picked.hour * 60 + picked.minute,
      );
    }
  }

  /// Returns the weekday (1..7) at position [index] in the display order,
  /// honouring the locale's first day of week.
  int _weekdayAt(int index, int firstDayIndex) {
    // DateTime.weekday is 1=Mon..7=Sun.
    // firstDayIndex is 0 (Sun) or 1 (Mon) per MaterialLocalizations.
    final start = firstDayIndex == 0 ? 7 : 1;
    return ((start - 1 + index) % 7) + 1;
  }

  String _weekdayShortName(int weekday, String locale) {
    // 2024-01-01 is a Monday, so DateTime(2024, 1, weekday) lands on the
    // requested weekday for weekday in 1..7.
    return DateFormat.E(locale).format(DateTime(2024, 1, weekday));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final dateFormat = DateFormat.yMd(locale);
    final symbol = Money.symbol(widget.store.currencyCode);
    final firstDayIndex =
        MaterialLocalizations.of(context).firstDayOfWeekIndex;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.historyFilterTitle,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l.historyFilterDateSection,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            RadioListTile<DateFilterMode>(
              contentPadding: EdgeInsets.zero,
              title: Text(l.historyFilterAnyDate),
              value: DateFilterMode.any,
              groupValue: _dateMode,
              onChanged: (v) => setState(
                () => _dateMode = v ?? DateFilterMode.any,
              ),
            ),
            RadioListTile<DateFilterMode>(
              contentPadding: EdgeInsets.zero,
              title: Text(l.historyFilterSpecificDay),
              value: DateFilterMode.specificDay,
              groupValue: _dateMode,
              onChanged: (v) => setState(() {
                _dateMode = v ?? _dateMode;
                _specificDay ??= _today();
              }),
              subtitle: _dateMode == DateFilterMode.specificDay &&
                      _specificDay != null
                  ? Row(
                      children: [
                        Expanded(
                          child: Text(
                            dateFormat.format(_specificDay!),
                          ),
                        ),
                        TextButton(
                          onPressed: _pickSpecificDay,
                          child: Text(l.historyFilterChange),
                        ),
                      ],
                    )
                  : null,
            ),
            RadioListTile<DateFilterMode>(
              contentPadding: EdgeInsets.zero,
              title: Text(l.historyFilterDateRange),
              value: DateFilterMode.range,
              groupValue: _dateMode,
              onChanged: (v) => setState(() {
                _dateMode = v ?? _dateMode;
                if (_dateRange == null) {
                  final today = _today();
                  _dateRange = DateTimeRange(
                    start: today.subtract(const Duration(days: 6)),
                    end: today,
                  );
                }
              }),
              subtitle:
                  _dateMode == DateFilterMode.range && _dateRange != null
                      ? Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${dateFormat.format(_dateRange!.start)} – '
                                '${dateFormat.format(_dateRange!.end)}',
                              ),
                            ),
                            TextButton(
                              onPressed: _pickDateRange,
                              child: Text(l.historyFilterChange),
                            ),
                          ],
                        )
                      : null,
            ),
            const SizedBox(height: 8),
            Text(
              l.historyFilterWeekdaySection,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: List.generate(7, (i) {
                final weekday = _weekdayAt(i, firstDayIndex);
                final selected = _weekdays.contains(weekday);
                return FilterChip(
                  label: Text(_weekdayShortName(weekday, locale)),
                  selected: selected,
                  onSelected: (v) {
                    setState(() {
                      if (v) {
                        _weekdays.add(weekday);
                      } else {
                        _weekdays.remove(weekday);
                      }
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 16),
            Text(
              l.historyFilterTimeOfDaySection,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.historyFilterTimeOfDaySection),
              value: _timeEnabled,
              onChanged: (v) => setState(() => _timeEnabled = v),
            ),
            if (_timeEnabled)
              Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickTimeFrom,
                        icon: const Icon(Icons.schedule, size: 18),
                        label: Text(
                          '${l.historyFilterTimeFrom} '
                          '${_timeFrom.format(context)}',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickTimeTo,
                        icon: const Icon(Icons.schedule, size: 18),
                        label: Text(
                          '${l.historyFilterTimeTo} '
                          '${_timeTo.format(context)}',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Text(
              l.historyFilterPriceSection,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            RadioListTile<PriceFilterMode>(
              contentPadding: EdgeInsets.zero,
              title: Text(l.historyFilterPriceAny),
              value: PriceFilterMode.any,
              groupValue: _priceMode,
              onChanged: (v) => setState(
                () => _priceMode = v ?? PriceFilterMode.any,
              ),
            ),
            RadioListTile<PriceFilterMode>(
              contentPadding: EdgeInsets.zero,
              title: Text(l.historyFilterPriceHas),
              value: PriceFilterMode.hasPrice,
              groupValue: _priceMode,
              onChanged: (v) => setState(
                () => _priceMode = v ?? _priceMode,
              ),
            ),
            RadioListTile<PriceFilterMode>(
              contentPadding: EdgeInsets.zero,
              title: Text(l.historyFilterPriceNo),
              value: PriceFilterMode.noPrice,
              groupValue: _priceMode,
              onChanged: (v) => setState(
                () => _priceMode = v ?? _priceMode,
              ),
            ),
            RadioListTile<PriceFilterMode>(
              contentPadding: EdgeInsets.zero,
              title: Text(l.historyFilterPriceRange),
              value: PriceFilterMode.inRange,
              groupValue: _priceMode,
              onChanged: (v) => setState(
                () => _priceMode = v ?? _priceMode,
              ),
            ),
            if (_priceMode == PriceFilterMode.inRange)
              Padding(
                padding:
                    const EdgeInsets.only(left: 16, right: 8, bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _priceMinCtrl,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: l.historyFilterPriceMin,
                          prefixText: '$symbol ',
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (_) => _persistPriceRange(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _priceMaxCtrl,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: l.historyFilterPriceMax,
                          prefixText: '$symbol ',
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (_) => _persistPriceRange(),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                TextButton(
                  onPressed: () =>
                      Navigator.pop(context, HistoryFilter.empty),
                  child: Text(l.historyFilterClearAll),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () =>
                      Navigator.pop(context, _buildFilter()),
                  child: Text(l.historyFilterApply),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}