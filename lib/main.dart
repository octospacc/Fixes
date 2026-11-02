import 'package:flutter/material.dart';
import 'app.dart';
import 'data/store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await Store.open();
  runApp(FixesApp(store: store));
}