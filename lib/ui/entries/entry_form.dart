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
  final _priceFocus = FocusNode();
  final _noteFocus = FocusNode();

  List<double> _priceSuggestions = const [];
  List<String> _noteSuggestions = const [];
  List<EntryPreset> _presets = const [];

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
      if (chosen != null) _itemId = chosen.id;
    }

    _priceCtrl.text = Money.formatForInput(_price);
    _noteCtrl.text = _note;
    _priceFocus.addListener(_onPriceFocusChanged);
    _noteFocus.addListener(_onNoteFocusChanged);
    _presets = widget.store.suggestPresetsForItem(_itemId);
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    _noteCtrl.dispose();
    _priceFocus.removeListener(_onPriceFocusChanged);
    _noteFocus.removeListener(_onNoteFocusChanged);
    _priceFocus.dispose();
    _noteFocus.dispose();
    super.dispose();
  }

  // ---------- Price suggestions ----------

  void _onPriceFocusChanged() {
    if (_priceFocus.hasFocus) {
      _refreshPriceSuggestions();
    } else if (_priceSuggestions.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        if (!_priceFocus.hasFocus && _priceSuggestions.isNotEmpty) {
          setState(() => _priceSuggestions = const []);
        }
      });
    }
  }

  void _refreshPriceSuggestions() {
    if (!_priceFocus.hasFocus) return;
    if (_itemId.isEmpty) {
      if (_priceSuggestions.isNotEmpty) {
        setState(() => _priceSuggestions = const []);
      }
      return;
    }
    final s = widget.store.suggestPricesForItem(_itemId);
    if (!mounted) return;
    setState(() => _priceSuggestions = s);
  }

  // ---------- Note suggestions ----------

  void _onNoteFocusChanged() {
    if (_noteFocus.hasFocus) {
      _refreshNoteSuggestions();
    } else if (_noteSuggestions.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        if (!_noteFocus.hasFocus && _noteSuggestions.isNotEmpty) {
          setState(() => _noteSuggestions = const []);
        }
      });
    }
  }

  void _refreshNoteSuggestions() {
    if (!_noteFocus.hasFocus) return;
    final item = widget.store.itemById(_itemId);
    final s = widget.store.suggestNotes(
      itemId: _itemId.isEmpty ? null : _itemId,
      category: item?.category,
      prefix: _noteCtrl.text,
      limit: 10,
    );
    if (!mounted) return;
    setState(() => _noteSuggestions = s);
  }

  // ---------- Presets ----------

  void _refreshPresets() {
    if (_itemId.isEmpty) {
      if (_presets.isNotEmpty) {
        setState(() => _presets = const []);
      }
      return;
    }
    final p = widget.store.suggestPresetsForItem(_itemId);
    if (!mounted) return;
    setState(() => _presets = p);
  }

  String _presetLabel(EntryPreset p, String currency, String locale) {
    final priceStr = p.price != null
        ? Money.format(p.price!, currencyCode: currency, locale: locale)
        : null;
    if (p.note.isEmpty) return priceStr ?? '';
    if (priceStr == null) return p.note;
    return '${p.note} · $priceStr';
  }

  void _applyPreset(EntryPreset p) {
    final priceText = Money.formatForInput(p.price);
    _priceCtrl.value = TextEditingValue(
      text: priceText,
      selection: TextSelection.collapsed(offset: priceText.length),
    );
    _noteCtrl.value = TextEditingValue(
      text: p.note,
      selection: TextSelection.collapsed(offset: p.note.length),
    );
    setState(() {
      _price = p.price;
      _note = p.note;
      _priceSuggestions = const [];
      _noteSuggestions = const [];
    });
    _priceFocus.unfocus();
    _noteFocus.unfocus();
  }

  // ---------- Date / time pickers ----------

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
    final currency = widget.store.currencyCode;

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
                setState(() => _itemId = v);
                if (_priceFocus.hasFocus) _refreshPriceSuggestions();
                if (_noteFocus.hasFocus) _refreshNoteSuggestions();
                _refreshPresets();
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
            focusNode: _priceFocus,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l.entryPricePerUnit,
              border: const OutlineInputBorder(),
            ),
            onChanged: (v) => _price = Money.parse(v),
          ),
          if (_priceSuggestions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _priceSuggestions.map((p) {
                  final label = Money.format(
                    p,
                    currencyCode: currency,
                    locale: locale,
                  );
                  return ActionChip(
                    label: Text(label),
                    onPressed: () {
                      final text = Money.formatForInput(p);
                      _priceCtrl.value = TextEditingValue(
                        text: text,
                        selection: TextSelection.collapsed(
                          offset: text.length,
                        ),
                      );
                      _price = p;
                      setState(() => _priceSuggestions = const []);
                      _priceFocus.unfocus();
                    },
                  );
                }).toList(),
              ),
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
              if (_noteFocus.hasFocus) _refreshNoteSuggestions();
            },
          ),
          if (_noteSuggestions.isNotEmpty)
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
                    children: _noteSuggestions.map((s) {
                      return ActionChip(
                        label: Text(s),
                        onPressed: () {
                          _noteCtrl.value = TextEditingValue(
                            text: s,
                            selection:
                                TextSelection.collapsed(offset: s.length),
                          );
                          _note = s;
                          setState(() => _noteSuggestions = const []);
                          _noteFocus.unfocus();
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          if (_presets.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              l.entryPresets,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _presets.map((p) {
                return ActionChip(
                  label: Text(_presetLabel(p, currency, locale)),
                  onPressed: () => _applyPreset(p),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}