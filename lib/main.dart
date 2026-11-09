import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/asset_data.dart';
import 'data/database.dart';
import 'logic/models.dart';
import 'ui/app_scope.dart';
import 'ui/cooking_timers.dart';
import 'ui/home_shell.dart';
import 'ui/timer_sound.dart';

Future<void> main() async {
  // Potrzebne, zanim użyjemy assets albo bazy przed runApp.
  WidgetsFlutterBinding.ensureInitialized();
  final catalog = (await AssetData.load()).toCatalog();
  final db = AppDatabase();
  final sound = TimerSound();
  runApp(MealprepApp(db: db, catalog: catalog, playSound: sound.play));
}

class MealprepApp extends StatefulWidget {
  const MealprepApp({
    super.key,
    required this.db,
    required this.catalog,
    this.playSound,
  });

  final AppDatabase db;
  final Catalog catalog;

  /// Dźwięk końca minutnika. W testach `null` (cisza).
  final Future<void> Function()? playSound;

  @override
  State<MealprepApp> createState() => _MealprepAppState();
}

class _MealprepAppState extends State<MealprepApp> {
  /// Klucz do komunikatów (SnackBar) z dowolnego miejsca, np. z minutnika,
  /// gdy jesteś na innej zakładce.
  final _messenger = GlobalKey<ScaffoldMessengerState>();

  late final CookingTimers _timers = CookingTimers(onFinished: _timerFinished);

  void _timerFinished(CookingTimer t) {
    widget.playSound?.call();
    _messenger.currentState?.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 10),
        content: Text('Minutnik gotowy: ${t.recipe.name}, krok ${t.step + 1}'),
      ),
    );
  }

  @override
  void dispose() {
    _timers.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const seed = Colors.green;
    return AppScope(
      db: widget.db,
      catalog: widget.catalog,
      timers: _timers,
      child: MaterialApp(
        title: 'Mealprep',
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: _messenger,
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
