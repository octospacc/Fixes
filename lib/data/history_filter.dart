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

  /// [pricePerUnit] is the entry's stored per-unit price, or null if the
  /// entry has no price set.
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

  const HistoryFilter({
    this.dateMode = DateFilterMode.any,
    this.specificDay,
    this.dateRange,
    this.timeRange,
    this.priceFilter = const PriceFilter(),
  });

  static const empty = HistoryFilter();

  bool get isActive =>
      (dateMode == DateFilterMode.specificDay && specificDay != null) ||
      (dateMode == DateFilterMode.range && dateRange != null) ||
      timeRange != null ||
      priceFilter.isActive;

  int get activeCount {
    var n = 0;
    if (dateMode == DateFilterMode.specificDay && specificDay != null) n++;
    if (dateMode == DateFilterMode.range && dateRange != null) n++;
    if (timeRange != null) n++;
    if (priceFilter.isActive) n++;
    return n;
  }
}