import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/app_info.dart';
import '../../data/csv_manager.dart';
import '../../data/dropbox_sync.dart';
import '../../data/store.dart';
import '../../l10n/generated/app_localizations.dart';

class SettingsView extends StatefulWidget {
  final Store store;

  const SettingsView({super.key, required this.store});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  bool _dropboxConnected = false;
  bool _checkingDropbox = true;

  @override
  void initState() {
    super.initState();
    _refreshDropboxStatus();
  }

  Future<void> _refreshDropboxStatus() async {
    final connected = await DropboxSync.isSignedIn();
    if (!mounted) return;
    setState(() {
      _dropboxConnected = connected;
      _checkingDropbox = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final store = widget.store;

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
            _sectionHeader(l.dropboxSection),
            const SizedBox(height: 8),
            _buildDropboxSection(context, l),
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
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l.settingsAppName),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.open_in_new,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
              onTap: _openRepo,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.settingsVersionLabel),
              trailing: Text(AppInfo.display),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDropboxSection(BuildContext context, AppLocalizations l) {
    if (_checkingDropbox) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_dropboxConnected) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.cloud_off),
        title: Text(l.dropboxConnect),
        subtitle: Text(l.dropboxNotConnected),
        onTap: () => _startConnect(context, l),
      );
    }

    final store = widget.store;
    final hasUnsynced = store.hasUnsyncedChanges;
    final error = Theme.of(context).colorScheme.error;

    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.cloud_done),
          title: Text(l.dropboxConnected),
          trailing: TextButton(
            onPressed: () async {
              await DropboxSync.signOut();
              await _refreshDropboxStatus();
            },
            child: Text(l.dropboxDisconnect),
          ),
        ),
        _buildSyncStatus(context, l, store, hasUnsynced, error),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.backup),
          title: Text(l.dropboxUpload),
          onTap: () => _upload(context, l),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.restore),
          title: Text(l.dropboxDownload),
          onTap: () => _download(context, l),
        ),
      ],
    );
  }

  Widget _buildSyncStatus(
    BuildContext context,
    AppLocalizations l,
    Store store,
    bool hasUnsynced,
    Color error,
  ) {
    final locale = Localizations.localeOf(context).toString();
    final dateFormat =
        DateFormat.yMd(locale).add_jm();

    final String title =
        hasUnsynced ? l.dropboxUnsynced : l.dropboxAllSynced;
    final String subtitle = store.lastSynced == null
        ? l.dropboxNeverSynced
        : l.dropboxLastSynced(
            dateFormat.format(store.lastSynced!.toLocal()),
          );

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        hasUnsynced ? Icons.sync_problem : Icons.sync,
        color: hasUnsynced ? error : null,
      ),
      title: Text(
        title,
        style: hasUnsynced ? TextStyle(color: error) : null,
      ),
      subtitle: Text(subtitle),
    );
  }

  Future<void> _startConnect(
    BuildContext context,
    AppLocalizations l,
  ) async {
    final verifier = DropboxSync.generateVerifier();
    final url = DropboxSync.buildAuthUrl(verifier);

    final code = await showDialog<String>(
      context: context,
      builder: (_) => _DropboxAuthDialog(authUrl: url),
    );
    if (code == null || code.isEmpty) return;

    try {
      await DropboxSync.completeAuth(code, verifier);
      await _refreshDropboxStatus();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.dropboxConnected)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.dropboxAuthError(e.toString()))),
      );
    }
  }

  Future<void> _upload(BuildContext context, AppLocalizations l) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        content: Text(l.dropboxUploadConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.dropboxUpload),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    try {
      await DropboxSync.upload(widget.store.toSyncJson());
      await widget.store.markSynced();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.dropboxUploaded)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.dropboxUploadError(e.toString()))),
      );
    }
  }

  Future<void> _download(BuildContext context, AppLocalizations l) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        content: Text(l.dropboxDownloadConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.dropboxDownload),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    try {
      final json = await DropboxSync.download();
      if (json == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.dropboxNoBackup)),
        );
        return;
      }
      await widget.store.mergeFromSync(json, force: true);
      await widget.store.markSynced();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.dropboxDownloaded)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.dropboxDownloadError(e.toString()))),
      );
    }
  }

  Future<void> _openRepo() async {
    final uri = Uri.parse(AppInfo.repoUrl);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.settingsRepoOpenFailed(AppInfo.repoUrl))),
      );
    }
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

class _DropboxAuthDialog extends StatefulWidget {
  final String authUrl;

  const _DropboxAuthDialog({required this.authUrl});

  @override
  State<_DropboxAuthDialog> createState() => _DropboxAuthDialogState();
}

class _DropboxAuthDialogState extends State<_DropboxAuthDialog> {
  final _codeCtrl = TextEditingController();

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l.dropboxAuthTitle),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l.dropboxAuthInstructions),
            const SizedBox(height: 12),
            SelectableText(
              widget.authUrl,
              style: const TextStyle(fontSize: 10),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.open_in_browser),
              label: Text(l.dropboxAuthOpen),
              onPressed: () async {
                final uri = Uri.parse(widget.authUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _codeCtrl,
              decoration: InputDecoration(
                labelText: l.dropboxAuthCode,
                hintText: l.dropboxAuthPaste,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.actionCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _codeCtrl.text.trim()),
          child: Text(l.dropboxAuthComplete),
        ),
      ],
    );
  }
}