/// Lokalna baza SQLite (biblioteka drift).
///
/// Tabele opisujemy jako klasy Darta, a `build_runner` generuje z nich kod
/// do pliku database.g.dart (nie edytuj go ręcznie). Po zmianie tabel uruchom:
///
///   dart run build_runner build
///
/// Przy zmianie struktury podbij [AppDatabase.schemaVersion] i dopisz migrację.
library;

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../logic/defaults.dart';
import '../logic/models.dart';
import '../logic/scaling.dart';
import '../logic/session_plan.dart';

part 'database.g.dart';

/// Cele makro. Zawsze dokładnie jeden wiersz (id = 1).
@DataClassName('GoalsRow')
class Goals extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  RealColumn get kcal => real()();
  RealColumn get protein => real()();
  RealColumn get fat => real()();
  RealColumn get carbs => real()();
  RealColumn get trainingExtraKcal => real()();

  /// Klucz makro: 'p', 'f' albo 'c'.
  TextColumn get trainingExtraFrom => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Lista posiłków w dniu.
@DataClassName('MealSlotRow')
class MealSlots extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get position => integer()();
  BoolColumn get prep => boolean()();
}

/// Sesje gotowania. Szczegóły planu (dni, posiłki, dania) są w kolumnie
/// [data] jako JSON: nigdy nie szukamy po nich w bazie, a jeden obiekt
/// łatwo będzie potem zsynchronizować z Supabase.
@DataClassName('SessionRow')
class Sessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get firstDay => dateTime()();
  TextColumn get data => text()();
  DateTimeColumn get updatedAt => dateTime()();
}

/// Odhaczone pozycje listy zakupów: jeden wiersz = produkt kupiony
/// w danej sesji. Brak wiersza = jeszcze nie kupiony.
@DataClassName('ShoppingCheckRow')
class ShoppingChecks extends Table {
  IntColumn get sessionId => integer()();
  TextColumn get productId => text()();
  DateTimeColumn get checkedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {sessionId, productId};
}

@DriftDatabase(tables: [Goals, MealSlots, Sessions, ShoppingChecks])
class AppDatabase extends _$AppDatabase {
  /// Bez argumentu: plik `mealprep.sqlite` w folderze danych aplikacji.
  /// W testach podajemy bazę w pamięci (`NativeDatabase.memory()`).
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'mealprep'));

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await saveSettings(defaultSettings);
      await saveMealSlots(defaultMealSlots);
    },
    // Baza z poprzedniej wersji aplikacji: dokładamy tylko to, czego brakuje.
    onUpgrade: (m, from, to) async {
      if (from < 2) await m.createTable(sessions);
      if (from < 3) await m.createTable(shoppingChecks);
    },
  );

  // ------------------------------------------------------------- cele

  Future<Settings> loadSettings() async =>
      _toSettings(await select(goals).getSingleOrNull());

  /// Jak [loadSettings], ale strumień: nowa wartość po każdej zmianie celów.
  Stream<Settings> watchSettings() =>
      select(goals).watchSingleOrNull().map(_toSettings);

  static Settings _toSettings(GoalsRow? row) {
    if (row == null) return defaultSettings;
    return Settings(
      target: Macros(kcal: row.kcal, p: row.protein, f: row.fat, c: row.carbs),
      trainingExtraKcal: row.trainingExtraKcal,
      trainingExtraFrom: Macro.fromKey(row.trainingExtraFrom),
    );
  }

  Future<void> saveSettings(Settings s) => into(goals).insertOnConflictUpdate(
    GoalsCompanion.insert(
      id: const Value(1),
      kcal: s.target.kcal,
      protein: s.target.p,
      fat: s.target.f,
      carbs: s.target.c,
      trainingExtraKcal: s.trainingExtraKcal,
      trainingExtraFrom: s.trainingExtraFrom.name,
    ),
  );

  // ---------------------------------------------------------- posiłki

  Future<List<MealSlot>> loadMealSlots() async {
    final rows = await (select(
      mealSlots,
    )..orderBy([(t) => OrderingTerm.asc(t.position)])).get();
    return [for (final r in rows) MealSlot(name: r.name, prep: r.prep)];
  }

  /// Zastępuje całą listę (w jednej transakcji: albo wszystko, albo nic).
  Future<void> saveMealSlots(List<MealSlot> slots) => transaction(() async {
    await delete(mealSlots).go();
    for (var i = 0; i < slots.length; i++) {
      await into(mealSlots).insert(
        MealSlotsCompanion.insert(
          name: slots[i].name,
          position: i,
          prep: slots[i].prep,
        ),
      );
    }
  });

  // ----------------------------------------------------------- sesje

  /// Wszystkie sesje, najnowsze na górze.
  Future<List<SessionPlan>> loadSessions() async =>
      _toPlans(await _sessionsQuery().get());

  /// Strumień sesji: nowa lista po każdej zmianie (np. w edytorze sesji).
  Stream<List<SessionPlan>> watchSessions() =>
      _sessionsQuery().watch().map(_toPlans);

  SimpleSelectStatement<$SessionsTable, SessionRow> _sessionsQuery() =>
      select(sessions)..orderBy([(t) => OrderingTerm.desc(t.firstDay)]);

  static List<SessionPlan> _toPlans(List<SessionRow> rows) => [
    for (final r in rows)
      SessionPlan.fromJson(
        jsonDecode(r.data) as Map<String, dynamic>,
        id: r.id,
      ),
  ];

  /// Zapisuje sesję i zwraca ją z nadanym ID.
  Future<SessionPlan> saveSession(SessionPlan plan) async {
    final row = SessionsCompanion(
      firstDay: Value(plan.firstDay),
      data: Value(jsonEncode(plan.toJson())),
      updatedAt: Value(DateTime.now()),
    );
    if (plan.id == null) {
      final id = await into(sessions).insert(row);
      return plan.copyWith(id: id);
    }
    await (update(sessions)..where((t) => t.id.equals(plan.id!))).write(row);
    return plan;
  }

  /// Usuwa sesję razem z jej odhaczeniami na liście zakupów.
  Future<void> deleteSession(int id) => transaction(() async {
    await (delete(shoppingChecks)..where((t) => t.sessionId.equals(id))).go();
    await (delete(sessions)..where((t) => t.id.equals(id))).go();
  });

  // ---------------------------------------------------- lista zakupów

  /// ID produktów odhaczonych w sesji (strumień, odświeża się po każdej zmianie).
  Stream<Set<String>> watchChecks(int sessionId) =>
      (select(shoppingChecks)..where((t) => t.sessionId.equals(sessionId)))
          .watch()
          .map((rows) => {for (final r in rows) r.productId});

  Future<void> setChecked(int sessionId, String productId, bool checked) async {
    if (checked) {
      await into(shoppingChecks).insertOnConflictUpdate(
        ShoppingChecksCompanion.insert(
          sessionId: sessionId,
          productId: productId,
          checkedAt: DateTime.now(),
        ),
      );
    } else {
      await (delete(shoppingChecks)..where(
            (t) =>
                t.sessionId.equals(sessionId) & t.productId.equals(productId),
          ))
          .go();
    }
  }

  Future<void> clearChecks(int sessionId) => (delete(
    shoppingChecks,
  )..where((t) => t.sessionId.equals(sessionId))).go();
}
