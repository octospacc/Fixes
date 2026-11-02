import 'package:flutter/material.dart';
import '../../data/category_icons.dart';
import '../../data/models.dart';
import '../../data/money.dart';
import '../../data/store.dart';
import '../../l10n/generated/app_localizations.dart';
import 'item_form.dart';

class ItemsView extends StatelessWidget {
  final Store store;

  const ItemsView({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final items = store.items;
        if (items.isEmpty) {
          return Center(child: Text(l.itemsEmpty));
        }
        final locale = Localizations.localeOf(context).toString();
        final error = Theme.of(context).colorScheme.error;

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
                    locale: locale,
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
                    tooltip: l.tileMore,
                    onSelected: (v) async {
                      if (v == 'delete') {
                        await _confirmAndDelete(context, item, entryCount);
                      }
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
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l.itemDeleteTitle(item.name)),
        content: Text(
          entryCount == 0
              ? l.itemDeleteBodyEmpty
              : l.itemDeleteBodyWithEntries(entryCount),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.actionCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.actionDelete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    store.deleteItem(item.id);
    messenger.showSnackBar(
      SnackBar(content: Text(l.itemDeleted(item.name))),
    );
  }
}