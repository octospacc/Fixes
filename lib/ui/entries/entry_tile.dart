import 'package:flutter/material.dart';
import '../../data/category_icons.dart';
import '../../data/models.dart';
import '../../data/money.dart';
import '../../data/store.dart';
import '../../l10n/generated/app_localizations.dart';
import 'entry_form.dart';

class EntryTile extends StatelessWidget {
  final Store store;
  final Entry entry;

  const EntryTile({super.key, required this.store, required this.entry});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final item = store.itemById(entry.itemId);
    final name = item?.name ?? l.tileUnknownItem;
    final priceText = entry.pricePerUnit != null
        ? Money.format(
            entry.pricePerUnit! * entry.quantity,
            currencyCode: store.currencyCode,
            locale: Localizations.localeOf(context).toString(),
          )
        : null;
    final hasNote = entry.note.isNotEmpty;
    final error = Theme.of(context).colorScheme.error;

    return ListTile(
      leading: Icon(iconForCategory(item?.category ?? '')),
      title: Text(name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_metaLine(entry, l)),
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
            tooltip: l.tileMore,
            onSelected: (v) {
              if (v == 'delete') _delete(context, name, l);
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: error),
                    const SizedBox(width: 12),
                    Text(
                      l.actionDelete,
                      style: TextStyle(color: error),
                    ),
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

  void _delete(
    BuildContext context,
    String name,
    AppLocalizations l,
  ) {
    final messenger = ScaffoldMessenger.of(context);
    final deleted = entry;
    store.deleteEntry(entry.id);
    messenger.showSnackBar(
      SnackBar(
        content: Text(l.tileDeleted(name)),
        action: SnackBarAction(
          label: l.tileUndo,
          onPressed: () => store.saveEntry(deleted),
        ),
      ),
    );
  }

  String _metaLine(Entry e, AppLocalizations l) {
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
          ? '${e.date.hour.toString().padLeft(2, '0')}:'
              '${e.date.minute.toString().padLeft(2, '0')}'
          : l.tileAllDay,
    );
    return parts.join(' · ');
  }
}