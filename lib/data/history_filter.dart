import 'package:flutter/material.dart';

/// A time-of-day range. Wraps midnight when [end] < [start].
class TimeRange {
  final TimeOfDay start;
  final TimeOfDay end;

  const TimeRange({required this.start, required this.end});

  int get _startMinutes => start.hour * 60 + start.minute;
  int get _endMinutes => end.hour * 60 + end.minute;

  bool matches(DateTime dt) {
    final m = dt.hour * 60 + dt.minute;
    if (_startMinutes <= _endMinutes) {
      return m >= _startMinutes && m <= _endMinutes;
    }
    return m >= _startMinutes || m <= _endMinutes;
  }
}

enum DateFilterMode { any, specificDay, range }

enum PriceFilterMode { any, hasPrice, noPrice, inRange }

class PriceFilter {
  final PriceFilterMode mode;
  final double? min;
  final double? max;

  const PriceFilter({
    this.mode = PriceFilterMode.any,
    this.min,
    this.max,
  });

  bool get isActive => mode != PriceFilterMode.any;

  bool matches(double? pricePerUnit) {
    switch (mode) {
      case PriceFilterMode.any:
        return true;
      case PriceFilterMode.hasPrice:
        return pricePerUnit != null;
      case PriceFilterMode.noPrice:
        return pricePerUnit == null;
      case PriceFilterMode.inRange:
        if (pricePerUnit == null) return false;
        if (min != null && pricePerUnit < min!) return false;
        if (max != null && pricePerUnit > max!) return false;
        return true;
    }
  }
}

class HistoryFilter {
  final DateFilterMode dateMode;
  final DateTime? specificDay;
  final DateTimeRange? dateRange;
  final TimeRange? timeRange;
  final PriceFilter priceFilter;

  /// Weekday numbers per [DateTime.weekday]: 1=Mon … 7=Sun.
  /// Empty means "any weekday".
  final Set<int> weekdays;

  const HistoryFilter({
    this.dateMode = DateFilterMode.any,
    this.specificDay,
    this.dateRange,
    this.timeRange,
    this.priceFilter = const PriceFilter(),
    this.weekdays = const {},
  });

  static const empty = HistoryFilter();

  bool get isActive =>
      (dateMode == DateFilterMode.specificDay && specificDay != null) ||
      (dateMode == DateFilterMode.range && dateRange != null) ||
      timeRange != null ||
      priceFilter.isActive ||
      weekdays.isNotEmpty;

  int get activeCount {
    var n = 0;
    if (dateMode == DateFilterMode.specificDay && specificDay != null) n++;
    if (dateMode == DateFilterMode.range && dateRange != null) n++;
    if (timeRange != null) n++;
    if (priceFilter.isActive) n++;
    if (weekdays.isNotEmpty) n++;
    return n;
  }

  bool matchesWeekday(DateTime dt) {
    if (weekdays.isEmpty) return true;
    return weekdays.contains(dt.weekday);
  }

  // ---------- Selective-clearing helpers ----------
  //
  // Each returns a new filter with one dimension removed, keeping every
  // other dimension intact. Used by the chip row when the user taps ×
  // on an individual filter. Centralised here so adding a new filter
  // dimension only touches this file.

  HistoryFilter withoutDate() => HistoryFilter(
        timeRange: timeRange,
        priceFilter: priceFilter,
        weekdays: weekdays,
      );

  HistoryFilter withoutTime() => HistoryFilter(
        dateMode: dateMode,
        specificDay: specificDay,
        dateRange: dateRange,
        priceFilter: priceFilter,
        weekdays: weekdays,
      );

  HistoryFilter withoutPrice() => HistoryFilter(
        dateMode: dateMode,
        specificDay: specificDay,
        dateRange: dateRange,
        timeRange: timeRange,
        weekdays: weekdays,
      );

  HistoryFilter withoutWeekdays() => HistoryFilter(
        dateMode: dateMode,
        specificDay: specificDay,
        dateRange: dateRange,
        timeRange: timeRange,
        priceFilter: priceFilter,
      );
}