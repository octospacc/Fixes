import 'package:flutter/material.dart';
import '../../data/csv_manager.dart';
import '../../data/store.dart';
import '../../l10n/generated/app_localizations.dart';

class SettingsView extends StatelessWidget {
  final Store store;

  const SettingsView({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionHeader(l.settingsCurrency),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: store.currencyCode,
              items: const ['USD', 'EUR', 'GBP', 'JPY', 'CHF', 'CNY']
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) {
                if (v != null) store.setCurrencyCode(v);
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            _sectionHeader(l.settingsLanguage),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: store.languageCode,
              items: [
                DropdownMenuItem(
                  value: '',
                  child: Text(l.settingsLanguageSystem),
                ),
                const DropdownMenuItem(
                  value: 'en',
                  child: Text('English'),
                ),
                const DropdownMenuItem(
                  value: 'it',
                  child: Text('Italiano'),
                ),
              ],
              onChanged: (v) {
                if (v != null) store.setLanguageCode(v);
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            _sectionHeader(l.settingsDayBoundary),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: store.dayStartHour,
              items: List.generate(24, (h) {
                return DropdownMenuItem(
                  value: h,
                  child: Text(_formatHour(h, l)),
                );
              }),
              onChanged: (v) {
                if (v != null) store.setDayStartHour(v);
              },
              decoration: InputDecoration(
                labelText: l.settingsDayStartsAt,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l.settingsDayBoundaryHint,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            _sectionHeader(l.settingsData),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.upload),
              title: Text(l.settingsExportCsv),
              onTap: () => CsvManager.export(store),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.download),
              title: Text(l.settingsImportCsv),
              onTap: () async {
                final messenger = ScaffoldMessenger.of(context);
                final result = await CsvManager.import(store, l);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(result.message),
                    duration: Duration(seconds: result.success ? 3 : 8),
                  ),
                );
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.delete_forever,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                l.settingsResetData,
                style:
                    TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              subtitle: Text(l.settingsResetDataSubtitle),
              onTap: () async {
                final scheme = Theme.of(context).colorScheme;
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text(l.resetTitle),
                    content: Text(l.resetBody),
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
                        child: Text(l.resetConfirm),
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
              title: Text(l.settingsAppLabel),
              trailing: Text(l.settingsAppName),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.settingsVersionLabel),
              trailing: const Text('1.2.0 (1)'),
            ),
          ],
        );
      },
    );
  }

  Widget _sectionHeader(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    );
  }

  String _formatHour(int h, AppLocalizations l) =>
      h == 0
          ? '00:00 (${l.settingsMidnight})'
          : '${h.toString().padLeft(2, '0')}:00';
}