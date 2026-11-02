import 'package:flutter/material.dart';
import 'data/store.dart';
import 'l10n/generated/app_localizations.dart';
import 'ui/root_shell.dart';

class FixesApp extends StatelessWidget {
  final Store store;

  const FixesApp({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        return MaterialApp(
          onGenerateTitle: (ctx) => AppLocalizations.of(ctx)!.appTitle,
          debugShowCheckedModeBanner: false,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: store.languageCode.isEmpty
              ? null
              : Locale(store.languageCode),
          theme: ThemeData(
            colorSchemeSeed: Colors.blue,
            useMaterial3: true,
          ),
          home: RootShell(store: store),
        );
      },
    );
  }
}