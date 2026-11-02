import 'dart:convert';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import '../l10n/generated/app_localizations.dart';
import 'models.dart';
import 'store.dart';

class ImportResult {
  final bool success;
  final String message;
  final int entriesAdded;
  final int itemsAdded;
  final int skipped;

  const ImportResult._({
    required this.success,
    required this.message,
    this.entriesAdded = 0,
    this.itemsAdded = 0,
    this.skipped = 0,
  });

  factory ImportResult.cancelled(AppLocalizations l) => ImportResult._(
        success: false,
        message: l.csvImportCancelled,
      );

  factory ImportResult.error(String msg) => ImportResult._(
        success: false,
        message: msg,
      );

  factory ImportResult.ok({
    required int entries,
    required int items,
    required int skipped,
    required AppLocalizations l,
  }) {
    final parts = <String>[l.csvImportedEntries(entries)];
    if (items > 0) parts.add(l.csvImportedNewItems(items));
    if (skipped > 0) parts.add('(${l.csvSkippedRows(skipped)})');
    return ImportResult._(
      success: true,
      message: parts.join(', '),
      entriesAdded: entries,
      itemsAdded: items,
      skipped: skipped,
    );
  }
}

class CsvManager {
  static const _headers = [
    'entry_id',
    'item_id',
    'item_name',
    'category',
    'default_price',
    'quantity',
    'date',
    'has_time',
    'price_per_unit',
    'note',
  ];

  static Future<void> export(Store store) async {
    final rows = <List<dynamic>>[_headers];
    for (final e in store.entries) {
      final item = store.itemById(e.itemId);
      rows.add([
        e.id,
        e.itemId,
        item?.name ?? '',
        item?.category ?? '',
        item?.defaultPrice ?? '',
        e.quantity,
        e.date.toIso8601String(),
        e.hasTime,
        e.pricePerUnit ?? '',
        e.note,
      ]);
    }
    final csvString = const ListToCsvConverter().convert(rows);

    await Share.shareXFiles([
      XFile.fromData(
        Uint8List.fromList(utf8.encode(csvString)),
        mimeType: 'text/csv',
        name: 'fixes_export.csv',
      ),
    ]);
  }

  static Future<ImportResult> import(
    Store store,
    AppLocalizations l,
  ) async {
    try {
      debugPrint('[csv.import] opening file selector');

      final XFile? file = await openFile(
        acceptedTypeGroups: const [
          XTypeGroup(label: 'CSV', extensions: ['csv']),
        ],
      );

      if (file == null) {
        return ImportResult.cancelled(l);
      }

      final rawBytes = await file.readAsBytes();
      if (rawBytes.isEmpty) {
        return ImportResult.error(l.csvImportEmptyFile);
      }

      var start = 0;
      if (rawBytes.length >= 3 &&
          rawBytes[0] == 0xEF &&
          rawBytes[1] == 0xBB &&
          rawBytes[2] == 0xBF) {
        start = 3;
      }
      final content =
          utf8.decode(rawBytes.sublist(start), allowMalformed: true);

      if (content.trim().isEmpty) {
        return ImportResult.error(l.csvImportEmptyFile);
      }

      final rows = const CsvToListConverter(shouldParseNumbers: false)
          .convert(content, eol: '\n');
      if (rows.isEmpty) {
        return ImportResult.error(l.csvImportNoRows);
      }

      final header = rows.first.map((e) => e.toString().trim()).toList();
      int idx(String name) =>
          header.indexWhere((h) => h.toLowerCase() == name.toLowerCase());

      final idIndex = idx('entry_id');
      final itemIdIndex = idx('item_id');
      final itemNameIndex = idx('item_name');
      final categoryIndex = idx('category');
      final defaultPriceIndex = idx('default_price');
      final qtyIndex = idx('quantity');
      final dateIndex = idx('date');
      final timeIndex = idx('has_time');
      final priceIndex = idx('price_per_unit');
      final noteIndex = idx('note');

      if (idIndex < 0) {
        return ImportResult.error(
          l.csvImportMissingEntryId(header.join(', ')),
        );
      }
      if (itemIdIndex < 0) {
        return ImportResult.error(l.csvImportMissingItemId);
      }
      if (dateIndex < 0) {
        return ImportResult.error(l.csvImportMissingDate);
      }

      final existingEntryIds = store.entries.map((e) => e.id).toSet();
      final existingItemIds = store.items.map((i) => i.id).toSet();

      var entriesAdded = 0;
      var itemsAdded = 0;
      var skipped = 0;

      for (final row in rows.skip(1)) {
        if (row.isEmpty) continue;

        final id = _cell(row, idIndex);
        if (id.isEmpty || existingEntryIds.contains(id)) {
          skipped++;
          continue;
        }

        final itemId = _cell(row, itemIdIndex);
        if (itemId.isEmpty) {
          skipped++;
          continue;
        }

        final date = _parseDate(_cell(row, dateIndex));
        if (date == null) {
          skipped++;
          continue;
        }

        if (!existingItemIds.contains(itemId)) {
          final itemName =
              itemNameIndex >= 0 ? _cell(row, itemNameIndex) : '';
          if (itemName.isNotEmpty) {
            final category =
                categoryIndex >= 0 ? _cell(row, categoryIndex) : '';
            final defaultPrice = defaultPriceIndex >= 0
                ? double.tryParse(_cell(row, defaultPriceIndex))
                : null;
            await store.saveItem(Item(
              id: itemId,
              name: itemName,
              category: category,
              defaultPrice: defaultPrice,
            ));
            existingItemIds.add(itemId);
            itemsAdded++;
          }
        }

        final qty = qtyIndex >= 0
            ? (double.tryParse(_cell(row, qtyIndex)) ?? 1.0)
            : 1.0;
        final price = priceIndex >= 0
            ? double.tryParse(_cell(row, priceIndex))
            : null;
        final hasTime = timeIndex >= 0 &&
            _cell(row, timeIndex).toLowerCase() == 'true';

        await store.saveEntry(Entry(
          id: id,
          itemId: itemId,
          quantity: qty,
          date: date,
          hasTime: hasTime,
          pricePerUnit: price,
          note: noteIndex >= 0 ? _cell(row, noteIndex) : '',
        ));
        existingEntryIds.add(id);
        entriesAdded++;
      }

      if (entriesAdded == 0 && itemsAdded == 0) {
        return ImportResult.error(l.csvImportNothingImported);
      }

      return ImportResult.ok(
        entries: entriesAdded,
        items: itemsAdded,
        skipped: skipped,
        l: l,
      );
    } catch (e, st) {
      debugPrint('[csv.import] error: $e\n$st');
      return ImportResult.error(l.csvImportFailed(e.toString()));
    }
  }

  static DateTime? _parseDate(String raw) {
    if (raw.isEmpty) return null;
    final iso = DateTime.tryParse(raw);
    if (iso != null) return iso;
    final asNum = double.tryParse(raw);
    if (asNum != null && asNum > 0) {
      return DateTime.fromMillisecondsSinceEpoch((asNum * 1000).round());
    }
    return null;
  }

  static String _cell(List<dynamic> row, int index) {
    if (index < 0 || index >= row.length) return '';
    final value = row[index];
    if (value == null) return '';
    return value.toString().trim();
  }
}