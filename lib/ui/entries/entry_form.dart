import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/category_icons.dart';
import '../../data/models.dart';
import '../../data/money.dart';
import '../../data/store.dart';
import '../../l10n/generated/app_localizations.dart';

class EntryForm extends StatefulWidget {
  final Store store;
  final Entry? entry;

  const EntryForm({super.key, required this.store, this.entry});

  @override
  State<EntryForm> createState() => _EntryFormState();
}

class _EntryFormState extends State<EntryForm> {
  String _itemId = '';
  double _quantity = 1;
  DateTime _date = DateTime.now();
  bool _hasTime = true;
  double? _price;
  String _note = '';

  final _priceCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final items = widget.store.items;
    final e = widget.entry;

    if (e != null) {
      _itemId = e.itemId;
      _quantity = e.quantity;
      _date = e.date;
      _hasTime = e.hasTime;
      _price = e.pricePerUnit;
      _note = e.note;
    } else if (items.isNotEmpty) {
      _itemId = items.first.id;
      _price = items.first.defaultPrice;
    }
    _priceCtrl.text = Money.formatForInput(_price);
    _noteCtrl.text = _note;
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() {
        _date = DateTime(
          date.year,
          date.month,
          date.day,
          _date.hour,
          _date.minute,
        );
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date),
      builder: (context, child) {
        // Force 24-hour format inside the picker. The app already displays
        // times as HH:MM everywhere, so the picker's input mode must use
        // the same format. Without this, on platforms where MediaQuery
        // reports a 12-hour preference that disagrees with the app's
        // locale, the picker shows 24h in text mode but the parser rejects
        // it — the "valid input read as invalid" bug.
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            alwaysUse24HourFormat: true,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _date = DateTime(
          _date.year,
          _date.month,
          _date.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  Future<void> _save() async {
    if (_itemId.isEmpty) return;
    if (widget.entry == null) {
      await widget.store.saveEntry(Entry(
        itemId: _itemId,
        quantity: _quantity,
        date: _date,
        hasTime: _hasTime,
        pricePerUnit: _price,
        note: _note,
      ));
    } else {
      final entry = widget.entry!
        ..quantity = _quantity
        ..date = _date
        ..hasTime = _hasTime
        ..pricePerUnit = _price
        ..note = _note;
      await widget.store.saveEntry(entry);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final items = widget.store.items;
    final locale = Localizations.localeOf(context).toString();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entry == null ? l.entryNew : l.entryEdit),
        actions: [
          TextButton(onPressed: _save, child: Text(l.actionSave)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<String>(
            value: _itemId.isEmpty ? null : _itemId,
            isExpanded: true,
            items: items
                .map((i) => DropdownMenuItem(
                      value: i.id,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(iconForCategory(i.category), size: 18),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              i.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) {
                setState(() {
                  _itemId = v;
                  _price = widget.store.itemById(v)?.defaultPrice;
                  _priceCtrl.text = Money.formatForInput(_price);
                });
              }
            },
            decoration: InputDecoration(
              labelText: l.entryItemLabel,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  l.entryQuantity,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () => setState(
                    () => _quantity = (_quantity - 1).clamp(1, 999)),
              ),
              Text(_quantity.toStringAsFixed(0)),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => setState(() => _quantity += 1),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.entryDate),
            subtitle: Text(
              DateFormat.yMd(locale).format(_date),
            ),
            trailing: TextButton(
              onPressed: _pickDate,
              child: Text(l.actionChange),
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.entryIncludeTime),
            value: _hasTime,
            onChanged: (v) => setState(() => _hasTime = v),
          ),
          if (_hasTime)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.entryTime),
              subtitle: Text(
                '${_date.hour.toString().padLeft(2, '0')}:'
                '${_date.minute.toString().padLeft(2, '0')}',
              ),
              trailing: TextButton(
                onPressed: _pickTime,
                child: Text(l.actionChange),
              ),
            ),
          const SizedBox(height: 16),
          TextField(
            controller: _priceCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l.entryPricePerUnit,
              border: const OutlineInputBorder(),
            ),
            onChanged: (v) => _price = Money.parse(v),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _noteCtrl,
            decoration: InputDecoration(
              labelText: l.entryNote,
              border: const OutlineInputBorder(),
            ),
            onChanged: (v) => _note = v,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}