import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/asset_data.dart';
import 'data/database.dart';
import 'logic/models.dart';
import 'ui/app_scope.dart';
import 'ui/home_shell.dart';

Future<void> main() async {
  // Potrzebne, zanim użyjemy assets albo bazy przed runApp.
  WidgetsFlutterBinding.ensureInitialized();
  final catalog = (await AssetData.load()).toCatalog();
  final db = AppDatabase();
  runApp(MealprepApp(db: db, catalog: catalog));
}

class MealprepApp extends StatelessWidget {
  const MealprepApp({super.key, required this.db, required this.catalog});

  final AppDatabase db;
  final Catalog catalog;

  @override
  Widget build(BuildContext context) {
    const seed = Colors.green;
    return AppScope(
      db: db,
      catalog: catalog,
      child: MaterialApp(
        title: 'Mealprep',
        debugShowCheckedModeBanner: false,
        // Polskie teksty wbudowanych elementów (kalendarz, „Anuluj", „OK").
        locale: const Locale('pl'),
        supportedLocales: const [Locale('pl')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        // Motyw jasny lub ciemny, zgodnie z ustawieniem systemu.
        themeMode: ThemeMode.system,
        theme: ThemeData(colorSchemeSeed: seed, brightness: Brightness.light),
        darkTheme: ThemeData(
          colorSchemeSeed: seed,
          brightness: Brightness.dark,
        ),
        home: const HomeShell(),
      ),
    );
  }
}
