import 'package:flutter/material.dart';
import '../data/store.dart';
import 'entries/entry_form.dart';
import 'history/history_view.dart';
import 'items/item_form.dart';
import 'items/items_view.dart';
import 'settings/settings_view.dart';
import 'stats/stats_view.dart';
import 'today/today_view.dart';

class RootShell extends StatefulWidget {
  final Store store;

  const RootShell({super.key, required this.store});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  static const _titles = [
    'Today',
    'History',
    'Statistics',
    'Items',
    'Settings',
  ];

  Widget? _buildFab() {
    switch (_index) {
      case 0:
        return FloatingActionButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => EntryForm(store: widget.store),
            ),
          ),
          tooltip: 'Add entry',
          child: const Icon(Icons.add),
        );
      case 3:
        return FloatingActionButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ItemForm(store: widget.store),
            ),
          ),
          tooltip: 'Add item',
          child: const Icon(Icons.add),
        );
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_index])),
      body: IndexedStack(
        index: _index,
        children: [
          TodayView(store: widget.store),
          HistoryView(store: widget.store),
          StatsView(store: widget.store),
          ItemsView(store: widget.store),
          SettingsView(store: widget.store),
        ],
      ),
      floatingActionButton: _buildFab(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.today), label: 'Today'),
          NavigationDestination(icon: Icon(Icons.history), label: 'History'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Stats'),
          NavigationDestination(icon: Icon(Icons.list), label: 'Items'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}