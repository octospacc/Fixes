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
      appBar: AppBar(title: Text(titles[_index])),
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