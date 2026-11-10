import 'package:flutter/material.dart';
import '../data/auto_sync.dart';
import '../data/store.dart';
import '../l10n/generated/app_localizations.dart';
import 'entries/entry_form.dart';
import 'history/history_view.dart';
import 'items/item_form.dart';
import 'items/items_view.dart';
import 'settings/settings_view.dart';
import 'stats/stats_view.dart';
import 'today/today_view.dart';

class RootShell extends StatefulWidget {
  final Store store;
  final AutoSyncService autoSync;

  const RootShell({
    super.key,
    required this.store,
    required this.autoSync,
  });

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final titles = [
      l.tabToday,
      l.tabHistory,
      l.tabStatistics,
      l.tabItems,
      l.tabSettings,
    ];

    Widget? fab;
    if (_index == 0) {
      fab = FloatingActionButton(
        tooltip: l.fabAddEntry,
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => EntryForm(store: widget.store),
          ),
        ),
        child: const Icon(Icons.add),
      );
    } else if (_index == 3) {
      fab = FloatingActionButton(
        tooltip: l.fabAddItem,
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ItemForm(store: widget.store),
          ),
        ),
        child: const Icon(Icons.add),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_index]),
        actions: [
          ListenableBuilder(
            listenable: widget.store,
            builder: (context, _) {
              if (!widget.store.dropboxConnected) {
                return const SizedBox.shrink();
              }
              return _SyncAction(
                store: widget.store,
                autoSync: widget.autoSync,
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: [
          TodayView(store: widget.store),
          HistoryView(store: widget.store),
          StatsView(store: widget.store),
          ItemsView(store: widget.store),
          SettingsView(
            store: widget.store,
            autoSync: widget.autoSync,
          ),
        ],
      ),
      floatingActionButton: fab,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.today),
            label: l.tabToday,
          ),
          NavigationDestination(
            icon: const Icon(Icons.history),
            label: l.tabHistory,
          ),
          NavigationDestination(
            icon: const Icon(Icons.bar_chart),
            label: l.tabStatistics,
          ),
          NavigationDestination(
            icon: const Icon(Icons.list),
            label: l.tabItems,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings),
            label: l.tabSettings,
          ),
        ],
      ),
    );
  }
}

class _SyncAction extends StatelessWidget {
  final Store store;
  final AutoSyncService autoSync;

  const _SyncAction({required this.store, required this.autoSync});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final error = Theme.of(context).colorScheme.error;

    if (store.syncing) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      );
    }

    final unsynced = store.hasUnsyncedChanges;
    final auto = store.autoSync;

    final IconData icon;
    final Color? color;
    if (unsynced) {
      icon = Icons.sync_problem;
      color = error;
    } else {
      icon = Icons.cloud_done_outlined;
      color = null;
    }

    final tooltip = auto
        ? (unsynced
            ? l.syncIndicatorUnsyncedAuto
            : l.syncIndicatorSyncedAuto)
        : (unsynced
            ? l.syncIndicatorUnsyncedManual
            : l.syncIndicatorSyncedManual);

    // When auto-sync is off, the icon is a passive indicator. Tapping it
    // would be a manual sync, which contradicts the user's choice to only
    // sync from the Settings screen.
    if (!auto) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Center(
          child: Tooltip(
            message: tooltip,
            child: Icon(icon, color: color),
          ),
        ),
      );
    }

    return IconButton(
      tooltip: tooltip,
      icon: Icon(icon, color: color),
      onPressed: () => autoSync.syncNow(),
    );
  }
}