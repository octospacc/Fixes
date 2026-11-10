import 'package:flutter/material.dart';
import '../../data/category_icons.dart';
import '../../data/models.dart';
import '../../data/money.dart';
import '../../data/store.dart';
import '../../l10n/generated/app_localizations.dart';

class QuickAddRow extends StatelessWidget {
  final Store store;
  final List<Item> items;

  const QuickAddRow({super.key, required this.store, required this.items});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(l.quickAddEmpty),
      );
    }

    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final item = items[i];
          return OutlinedButton(
            onPressed: () => _quickAdd(item),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(iconForCategory(item.category), size: 18),
                    const SizedBox(width: 6),
                    Text(item.name, softWrap: false),
                  ],
                ),
                if (item.defaultPrice != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    Money.formatForInput(item.defaultPrice),
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _quickAdd(Item item) async {
    await store.saveEntry(Entry(
      itemId: item.id,
      date: DateTime.now(),
      hasTime: true,
      pricePerUnit: item.defaultPrice,
    ));
  }
}
