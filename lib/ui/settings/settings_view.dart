import 'package:flutter/material.dart';
import '../../data/csv_manager.dart';
import '../../data/store.dart';

class SettingsView extends StatelessWidget {
  final Store store;

  const SettingsView({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _SectionHeader('Currency'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: store.currencyCode,
              items: const ['USD', 'EUR', 'GBP', 'JPY', 'CHF', 'CNY']
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) {
                if (v != null) store.setCurrencyCode(v);
              },
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            const _SectionHeader('Day boundary'),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: store.dayStartHour,
              items: List.generate(24, (h) {
                return DropdownMenuItem(
                  value: h,
                  child: Text(_formatHour(h)),
                );
              }),
              onChanged: (v) {
                if (v != null) store.setDayStartHour(v);
              },
              decoration: const InputDecoration(
                labelText: 'Day starts at',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Used for grouping in Today and History. Storage is unaffected.',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            const _SectionHeader('Data'),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.upload),
              title: const Text('Export CSV'),
              onTap: () => CsvManager.export(store),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.download),
              title: const Text('Import CSV'),
              onTap: () async {
                final messenger = ScaffoldMessenger.of(context);
                final result = await CsvManager.import(store);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(result.message),
                    duration: Duration(seconds: result.success ? 3 : 8),
                  ),
                );
              },
            ),
        // ... after the Import CSV ListTile, before const Divider()
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            Icons.delete_forever,
            color: Theme.of(context).colorScheme.error,
          ),
          title: Text(
            'Reset data',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          subtitle: const Text('Delete all entries and items'),
          onTap: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Reset data?'),
                content: const Text(
                  'All entries and items will be permanently deleted. '
                  'Settings (currency, day boundary) are kept. '
                  'This cannot be undone.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton.tonal(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Reset'),
                  ),
                ],
              ),
            );
            if (ok == true) await store.reset();
          },
        ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('App'),
              trailing: const Text('Fixes'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Version'),
              trailing: const Text('1.2.0 (1)'),
            ),
          ],
        );
      },
    );
  }

  String _formatHour(int h) =>
      h == 0 ? '00:00 (midnight)' : '${h.toString().padLeft(2, '0')}:00';
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    );
  }
}