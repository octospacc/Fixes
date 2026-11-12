import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/category_icons.dart';
import '../../data/models.dart';
import '../../data/store.dart';
import '../../l10n/generated/app_localizations.dart';
import '../entries/entry_form.dart';

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
          return Tooltip(
            // manual: hover works on desktop/web, but long-press on mobile
            // is left free for the InkWell — otherwise the tooltip would
            // claim the gesture and the detail form would never open.
            triggerMode: TooltipTriggerMode.manual,
            waitDuration: const Duration(milliseconds: 600),
            exitDuration: const Duration(milliseconds: 100),
            message: l.quickAddHint,
            child: Material(
              color: Colors.transparent,
              shape: StadiumBorder(
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => _quickAdd(item),
                onLongPress: () => _openDetail(context, item),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
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
                          item.defaultPrice!.toStringAsFixed(2),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
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

  void _openDetail(BuildContext context, Item item) {
    // Tactile confirmation that the gesture registered. No-op on platforms
    // without haptics (web, desktop) — safe to call unconditionally.
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EntryForm(
          store: store,
          initialItemId: item.id,
        ),
      ),
    );
  }
}