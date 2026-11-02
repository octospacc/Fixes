import 'package:flutter/material.dart';
import '../../data/category_icons.dart';
import '../../data/models.dart';
import '../../data/store.dart';
import '../../l10n/generated/app_localizations.dart';

class ItemForm extends StatefulWidget {
  final Store store;
  final Item? item;

  const ItemForm({super.key, required this.store, this.item});

  @override
  State<ItemForm> createState() => _ItemFormState();
}

class _ItemFormState extends State<ItemForm> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _categoryCtrl;
  late final TextEditingController _priceCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.item?.name ?? '');
    _categoryCtrl = TextEditingController(text: widget.item?.category ?? '');
    _priceCtrl = TextEditingController(
      text: widget.item?.defaultPrice?.toStringAsFixed(2) ?? '',
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _categoryCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    final price = double.tryParse(_priceCtrl.text);
    final category = _categoryCtrl.text.trim();

    if (widget.item == null) {
      await widget.store.saveItem(Item(
        name: name,
        category: category,
        defaultPrice: price,
      ));
    } else {
      final item = widget.item!
        ..name = name
        ..category = category
        ..defaultPrice = price;
      await widget.store.saveItem(item);
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item == null ? l.itemNew : l.itemEdit),
        actions: [
          TextButton(onPressed: _save, child: Text(l.actionSave)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: InputDecoration(
              labelText: l.itemName,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _categoryCtrl,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: l.itemCategory,
              prefixIcon: Icon(iconForCategory(_categoryCtrl.text)),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _priceCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l.itemDefaultPrice,
              border: const OutlineInputBorder(),
            ),
          ),
          if (widget.item == null) ...[
            const SizedBox(height: 24),
            Text(
              l.itemSuggestions,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...StarterPresets.forLocale(l).map((s) {
              return ListTile(
                leading: Icon(iconForCategory(s['category']!)),
                title: Text(s['name']!),
                subtitle: Text(s['category']!),
                onTap: () {
                  setState(() {
                    _nameCtrl.text = s['name']!;
                    _categoryCtrl.text = s['category']!;
                  });
                },
              );
            }),
          ],
        ],
      ),
    );
  }
}