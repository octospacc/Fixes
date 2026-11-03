import 'package:flutter/material.dart';

/// A time-of-day range. Wraps midnight when [end] < [start]
/// (e.g. 22:00 – 06:00 catches late-night entries).
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

class HistoryFilter {
  final DateFilterMode dateMode;
  final DateTime? specificDay;
  final DateTimeRange? dateRange;
  final TimeRange? timeRange;

  const HistoryFilter({
    this.dateMode = DateFilterMode.any,
    this.specificDay,
    this.dateRange,
    this.timeRange,
  });

  static const empty = HistoryFilter();

  bool get isActive =>
      (dateMode == DateFilterMode.specificDay && specificDay != null) ||
      (dateMode == DateFilterMode.range && dateRange != null) ||
      timeRange != null;

  int get activeCount {
    var n = 0;
    if (dateMode == DateFilterMode.specificDay && specificDay != null) n++;
    if (dateMode == DateFilterMode.range && dateRange != null) n++;
    if (timeRange != null) n++;
    return n;
  }
}