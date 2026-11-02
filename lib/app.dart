import 'package:flutter/material.dart';
import 'data/store.dart';
import 'ui/root_shell.dart';

class FixesApp extends StatelessWidget {
  final Store store;

  const FixesApp({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fixes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: RootShell(store: store),
    );
  }
}