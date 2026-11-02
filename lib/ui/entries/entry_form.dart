import 'package:flutter/material.dart';
import '../../data/models.dart';
import '../../data/store.dart';

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
    }
    _priceCtrl.text = _price?.toStringAsFixed(2) ?? '';
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
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date),
    );
    if (time != null) {
      setState(() {
        _date = DateTime(
          _date.year,
          _date.month,
          _date.day,
          time.hour,
          time.minute,
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
    final items = widget.store.items;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entry == null ? 'New entry' : 'Edit entry'),
        actions: [
          TextButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<String>(
            value: _itemId.isEmpty ? null : _itemId,
            items: items
                .map((i) =>
                    DropdownMenuItem(value: i.id, child: Text(i.name)))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _itemId = v);
            },
            decoration: const InputDecoration(
              labelText: 'Item',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Quantity: ${_quantity.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () => setState(
                    () => _quantity = (_quantity - 1).clamp(1, 999)),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => setState(() => _quantity += 1),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Date'),
            subtitle: Text('${_date.day}/${_date.month}/${_date.year}'),
            trailing: TextButton(
              onPressed: _pickDate,
              child: const Text('Change'),
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Include time'),
            value: _hasTime,
            onChanged: (v) => setState(() => _hasTime = v),
          ),
          if (_hasTime)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Time'),
              subtitle: Text(
                '${_date.hour.toString().padLeft(2, '0')}:'
                '${_date.minute.toString().padLeft(2, '0')}',
              ),
              trailing: TextButton(
                onPressed: _pickTime,
                child: const Text('Change'),
              ),
            ),
          const SizedBox(height: 16),
          TextField(
            controller: _priceCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Price per unit',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => _price = double.tryParse(v),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _noteCtrl,
            decoration: const InputDecoration(
              labelText: 'Note',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => _note = v,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}