import 'package:flutter/material.dart';
import 'app.dart';
import 'data/app_info.dart';
import 'data/auto_sync.dart';
import 'data/dropbox_sync.dart';
import 'data/store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppInfo.load();
  final store = await Store.open();
  final connected = await DropboxSync.isSignedIn();
  store.setDropboxConnected(connected);
  final autoSync = AutoSyncService(store);
  runApp(FixesApp(store: store, autoSync: autoSync));
}