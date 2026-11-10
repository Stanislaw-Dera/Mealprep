import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/asset_data.dart';
import 'data/database.dart';
import 'data/supabase_sync.dart';
import 'data/sync.dart';

import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

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
  // Synchronizacja tylko, gdy zbudowano z --dart-define-from-file=supabase.json.
  SyncController? sync;
  if (supabaseConfigured) {
    await initSupabase();
    final client = Supabase.instance.client;
    sync = SyncController(
      db: db,
      auth: SupabaseAuth(client),
      remote: SupabaseRemote(client),
    );
    await sync.start();
  }
  runApp(
    MealprepApp(db: db, catalog: catalog, playSound: sound.play, sync: sync),
  );
}

class MealprepApp extends StatefulWidget {
  const MealprepApp({
    super.key,
    required this.db,
    required this.catalog,
    this.playSound,
    this.sync,
  });

  final AppDatabase db;
  final Catalog catalog;

  /// Dźwięk końca minutnika. W testach `null` (cisza).
  final Future<void> Function()? playSound;

  /// Synchronizacja z Supabase (`null` = wyłączona, np. w testach).
  final SyncController? sync;

  @override
  State<MealprepApp> createState() => _MealprepAppState();
}

class _MealprepAppState extends State<MealprepApp> {
  /// Klucz do komunikatów (SnackBar) z dowolnego miejsca, np. z minutnika,
  /// gdy jesteś na innej zakładce.
  final _messenger = GlobalKey<ScaffoldMessengerState>();

  late final CookingTimers _timers = CookingTimers(onFinished: _timerFinished);

  /// Po powrocie do aplikacji (np. telefon wyjęty z kieszeni w sklepie)
  /// pobieramy zmiany z innych urządzeń.
  late final AppLifecycleListener _lifecycle = AppLifecycleListener(
    onResume: () => widget.sync?.syncNow(),
  );

  @override
  void initState() {
    super.initState();
    _lifecycle; // utworzenie słuchacza
  }

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
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const seed = Colors.green;
    return AppScope(
      db: widget.db,
      catalog: widget.catalog,
      timers: _timers,
      sync: widget.sync,
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
