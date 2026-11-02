import 'dart:convert';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
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

  factory ImportResult.cancelled() => const ImportResult._(
        success: false,
        message: 'Import cancelled',
      );

  factory ImportResult.error(String msg) => ImportResult._(
        success: false,
        message: msg,
      );

  factory ImportResult.ok({
    required int entries,
    required int items,
    required int skipped,
  }) =>
      ImportResult._(
        success: true,
        message: items > 0
            ? 'Imported $entries entries, $items new items'
                '${skipped > 0 ? ' ($skipped skipped)' : ''}'
            : 'Imported $entries entries'
                '${skipped > 0 ? ' ($skipped skipped)' : ''}',
        entriesAdded: entries,
        itemsAdded: items,
        skipped: skipped,
      );
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

  // ---------- EXPORT ----------

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

  // ---------- IMPORT ----------

  static Future<ImportResult> import(Store store) async {
    try {
      debugPrint('[csv.import] opening picker');
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );

      if (picked == null || picked.files.isEmpty) {
        debugPrint('[csv.import] cancelled (no files)');
        return ImportResult.cancelled();
      }

      final file = picked.files.single;
      debugPrint(
        '[csv.import] picked "${file.name}" (${file.size}B, '
        'bytes=${file.bytes?.length})',
      );

      final rawBytes = file.bytes;
      if (rawBytes == null) {
        debugPrint('[csv.import] bytes are null — withData did not populate');
        return ImportResult.error(
          'Could not read the file contents. '
          'Try picking the file again.',
        );
      }

      // Strip UTF-8 BOM if present (EF BB BF).
      var start = 0;
      if (rawBytes.length >= 3 &&
          rawBytes[0] == 0xEF &&
          rawBytes[1] == 0xBB &&
          rawBytes[2] == 0xBF) {
        debugPrint('[csv.import] UTF-8 BOM detected, stripping');
        start = 3;
      }
      final content =
          utf8.decode(rawBytes.sublist(start), allowMalformed: true);
      debugPrint('[csv.import] content length=${content.length}');

      if (content.trim().isEmpty) {
        return ImportResult.error('CSV file is empty');
      }

      final delimiter = _detectDelimiter(content);
      debugPrint('[csv.import] delimiter="$delimiter"');

      final rows =
          const CsvToListConverter(shouldParseNumbers: false)
              .convert(content, eol: '\n');
      debugPrint('[csv.import] parsed ${rows.length} rows');

      if (rows.isEmpty) {
        return ImportResult.error('CSV has no rows');
      }

      final header = rows.first.map((e) => e.toString().trim()).toList();
      debugPrint('[csv.import] header=$header');

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
          'Missing "entry_id" column. '
          'Header was: ${header.join(", ")}',
        );
      }
      if (itemIdIndex < 0) {
        return ImportResult.error('Missing "item_id" column.');
      }
      if (dateIndex < 0) {
        return ImportResult.error('Missing "date" column.');
      }

      final existingEntryIds = store.entries.map((e) => e.id).toSet();
      final existingItemIds = store.items.map((i) => i.id).toSet();

      var entriesAdded = 0;
      var itemsAdded = 0;
      var skipped = 0;

      for (final row in rows.skip(1)) {
        if (row.isEmpty) continue;

        final id = _cell(row, idIndex);
        if (id.isEmpty) {
          skipped++;
          continue;
        }
        if (existingEntryIds.contains(id)) {
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
          debugPrint('[csv.import] bad date for entry $id');
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

      debugPrint(
        '[csv.import] done: entries=$entriesAdded, items=$itemsAdded, '
        'skipped=$skipped',
      );

      if (entriesAdded == 0 && itemsAdded == 0) {
        return ImportResult.error(
          'Nothing imported. '
          '${skipped > 0 ? "$skipped rows were skipped " : ""}'
          '(all entries already present, or file has no valid rows).',
        );
      }

      return ImportResult.ok(
        entries: entriesAdded,
        items: itemsAdded,
        skipped: skipped,
      );
    } catch (e, st) {
      debugPrint('[csv.import] error: $e\n$st');
      return ImportResult.error('Import failed: $e');
    }
  }

  // ---------- helpers ----------

  static String _detectDelimiter(String content) {
    final firstLine =
        content.split(RegExp(r'[\r\n]')).firstWhere((l) => l.isNotEmpty,
            orElse: () => '');
    if (firstLine.isEmpty) return ',';
    final commas = ','.allMatches(firstLine).length;
    final semis = ';'.allMatches(firstLine).length;
    final tabs = '\t'.allMatches(firstLine).length;
    if (semis > commas && semis > tabs) return ';';
    if (tabs > commas && tabs > semis) return '\t';
    return ',';
  }

  static DateTime? _parseDate(String raw) {
    if (raw.isEmpty) return null;
    final iso = DateTime.tryParse(raw);
    if (iso != null) return iso;
    // Try epoch seconds (e.g. 1793630400.000) for older exports.
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