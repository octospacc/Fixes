import 'package:flutter/material.dart';
import '../../data/category_icons.dart';
import '../../data/models.dart';
import '../../data/money.dart';
import '../../data/store.dart';
import 'item_form.dart';

class ItemsView extends StatelessWidget {
  final Store store;

  const ItemsView({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final items = store.items;

        if (items.isEmpty) {
          return const Center(child: Text('No items yet'));
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 88),
          itemCount: items.length,
          itemBuilder: (context, i) {
            final item = items[i];
            final entryCount =
                store.entries.where((e) => e.itemId == item.id).length;
            final priceText = item.defaultPrice != null
                ? Money.format(
                    item.defaultPrice!,
                    currencyCode: store.currencyCode,
                  )
                : null;

            return ListTile(
              leading: Icon(iconForCategory(item.category)),
              title: Text(item.name),
              subtitle:
                  item.category.isNotEmpty ? Text(item.category) : null,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (priceText != null) Text(priceText),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_horiz, size: 20),
                    tooltip: 'More',
                    onSelected: (v) async {
                      if (v == 'delete') {
                        await _confirmAndDelete(
                          context,
                          item,
                          entryCount,
                        );
                      }
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
                  builder: (_) => ItemForm(store: store, item: item),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmAndDelete(
    BuildContext context,
    Item item,
    int entryCount,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete "${item.name}"?'),
        content: Text(
          entryCount == 0
              ? 'This item will be permanently removed.'
              : 'This item and its $entryCount '
                  '${entryCount == 1 ? "entry" : "entries"} '
                  'will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    store.deleteItem(item.id);
    messenger.showSnackBar(
      SnackBar(content: Text('Deleted "${item.name}"')),
    );
  }
}