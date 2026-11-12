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

  /// Optional item to preselect when creating a new entry. Ignored when
  /// [entry] is non-null (editing an existing entry loads its own item).
  final String? initialItemId;

  const EntryForm({
    super.key,
    required this.store,
    this.entry,
    this.initialItemId,
  });

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
  final _noteFocus = FocusNode();

  List<String> _suggestions = const [];

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
    } else {
      final Item? target;
      if (widget.initialItemId != null) {
        target = widget.store.itemById(widget.initialItemId!);
      } else {
        target = null;
      }
      final chosen = target ?? (items.isNotEmpty ? items.first : null);
      if (chosen != null) {
        _itemId = chosen.id;
        _price = chosen.defaultPrice;
      }
    }
    _priceCtrl.text = Money.formatForInput(_price);
    _noteCtrl.text = _note;
    _noteFocus.addListener(_onNoteFocusChanged);
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    _noteCtrl.dispose();
    _noteFocus.removeListener(_onNoteFocusChanged);
    _noteFocus.dispose();
    super.dispose();
  }

  void _onNoteFocusChanged() {
    if (_noteFocus.hasFocus) {
      _refreshSuggestions();
    } else if (_suggestions.isNotEmpty) {
      // Defer the clear. TextField.onTapOutside unfocuses synchronously
      // on pointer-down; without the delay, setState removes the chip
      // from the widget tree before pointer-up reaches its onPressed,
      // so tapping a chip appears to do nothing.
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        if (!_noteFocus.hasFocus && _suggestions.isNotEmpty) {
          setState(() => _suggestions = const []);
        }
      });
    }
  }

  void _refreshSuggestions() {
    final item = widget.store.itemById(_itemId);
    final s = widget.store.suggestNotes(
      itemId: _itemId.isEmpty ? null : _itemId,
      category: item?.category,
      prefix: _noteCtrl.text,
      limit: 10,
    );
    if (!mounted) return;
    setState(() => _suggestions = s);
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
                if (_noteFocus.hasFocus && _noteCtrl.text.isEmpty) {
                  _refreshSuggestions();
                }
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
            focusNode: _noteFocus,
            decoration: InputDecoration(
              labelText: l.entryNote,
              border: const OutlineInputBorder(),
            ),
            onChanged: (v) {
              _note = v;
              if (_noteFocus.hasFocus) {
                _refreshSuggestions();
              }
            },
          ),
          if (_suggestions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.entryNoteSuggestions,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _suggestions.map((s) {
                      return ActionChip(
                        label: Text(s),
                        onPressed: () {
                          _noteCtrl.value = TextEditingValue(
                            text: s,
                            selection:
                                TextSelection.collapsed(offset: s.length),
                          );
                          _note = s;
                          setState(() => _suggestions = const []);
                          _noteFocus.unfocus();
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}