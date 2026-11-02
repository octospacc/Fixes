import 'package:flutter/material.dart';
import 'app.dart';
import 'data/app_info.dart';
import 'data/store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppInfo.load();
  final store = await Store.open();
  runApp(FixesApp(store: store));
}