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

        return Column(
          children: [
            _Toolbar(
              count: items.length,
              showSort: items.length >= 2,
              onSort: () => _sortByUsage(context, l),
              l: l,
            ),
            Expanded(
              child: ReorderableListView.builder(
                padding: const EdgeInsets.only(bottom: 88),
                itemCount: items.length,
                buildDefaultDragHandles: false,
                onReorder: (oldIndex, newIndex) {
                  if (oldIndex < newIndex) newIndex -= 1;
                  final moved = items[oldIndex];
                  final updated = List<Item>.from(items);
                  updated.removeAt(oldIndex);
                  updated.insert(newIndex, moved);
                  store.reorderItems(updated);
                },
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
                    key: ValueKey(item.id),
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ReorderableDragStartListener(
                          index: i,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Icon(
                              Icons.drag_handle,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        ),
                        Icon(iconForCategory(item.category)),
                      ],
                    ),
                    title: Text(item.name),
                    subtitle: item.category.isNotEmpty
                        ? Text(item.category)
                        : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (priceText != null) Text(priceText),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_horiz, size: 20),
                          tooltip: l.tileMore,
                          onSelected: (v) async {
                            if (v == 'delete') {
                              await _confirmAndDelete(
                                context,
                                item,
                                entryCount,
                                l,
                              );
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
              ),
            ),
          ],
        );
      },
    );
  }

  void _sortByUsage(BuildContext context, AppLocalizations l) {
    final before = List<Item>.from(store.items);
    store.sortItemsByUsage();
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(l.sortedByUsage),
        action: SnackBarAction(
          label: l.tileUndo,
          onPressed: () => store.reorderItems(before),
        ),
      ),
    );
  }

  Future<void> _confirmAndDelete(
    BuildContext context,
    Item item,
    int entryCount,
    AppLocalizations l,
  ) async {
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

class _Toolbar extends StatelessWidget {
  final int count;
  final bool showSort;
  final VoidCallback onSort;
  final AppLocalizations l;

  const _Toolbar({
    required this.count,
    required this.showSort,
    required this.onSort,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
      child: Row(
        children: [
          Text(
            l.itemsCount(count),
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          if (showSort)
            TextButton.icon(
              icon: const Icon(Icons.sort, size: 18),
              label: Text(l.sortByUsage),
              onPressed: onSort,
            ),
        ],
      ),
    );
  }
}