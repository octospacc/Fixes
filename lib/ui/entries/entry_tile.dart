import 'package:flutter/material.dart';
import '../../data/category_icons.dart';
import '../../data/models.dart';
import '../../data/money.dart';
import '../../data/store.dart';
import 'entry_form.dart';

class EntryTile extends StatelessWidget {
  final Store store;
  final Entry entry;

  const EntryTile({super.key, required this.store, required this.entry});

  @override
  Widget build(BuildContext context) {
    final item = store.itemById(entry.itemId);
    final name = item?.name ?? 'Unknown';
    final priceText = entry.pricePerUnit != null
        ? Money.format(
            entry.pricePerUnit! * entry.quantity,
            currencyCode: store.currencyCode,
          )
        : null;
    final hasNote = entry.note.isNotEmpty;

    return ListTile(
      leading: Icon(iconForCategory(item?.category ?? '')),
      title: Text(name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_metaLine(entry)),
          if (hasNote)
            Text(
              entry.note,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
      isThreeLine: hasNote,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (priceText != null) Text(priceText),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz, size: 20),
            tooltip: 'More',
            onSelected: (v) {
              if (v == 'delete') _delete(context, name);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline),
                    SizedBox(width: 12),
                    Text('Delete'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EntryForm(store: store, entry: entry),
        ),
      ),
    );
  }

  void _delete(BuildContext context, String name) {
    final messenger = ScaffoldMessenger.of(context);
    final deleted = entry;
    store.deleteEntry(entry.id);
    messenger.showSnackBar(
      SnackBar(
        content: Text('Deleted "$name"'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => store.saveEntry(deleted),
        ),
      ),
    );
  }

  String _metaLine(Entry e) {
    final parts = <String>[];
    if (e.quantity > 1) {
      parts.add(
        e.quantity == e.quantity.roundToDouble()
            ? '×${e.quantity.toInt()}'
            : '×${e.quantity}',
      );
    }
    parts.add(
      e.hasTime
          ? '${e.date.hour.toString().padLeft(2, '0')}:${e.date.minute.toString().padLeft(2, '0')}'
          : 'All day',
    );
    return parts.join(' · ');
  }
}