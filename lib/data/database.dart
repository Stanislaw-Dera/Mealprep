/// Lokalna baza SQLite (biblioteka drift).
///
/// Tabele opisujemy jako klasy Darta, a `build_runner` generuje z nich kod
/// do pliku database.g.dart (nie edytuj go ręcznie). Po zmianie tabel uruchom:
///
///   dart run build_runner build
///
/// Przy zmianie struktury podbij [AppDatabase.schemaVersion] i dopisz migrację.
library;

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../logic/defaults.dart';
import '../logic/models.dart';
import '../logic/scaling.dart';

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

@DriftDatabase(tables: [Goals, MealSlots])
class AppDatabase extends _$AppDatabase {
  /// Bez argumentu: plik `mealprep.sqlite` w folderze danych aplikacji.
  /// W testach podajemy bazę w pamięci (`NativeDatabase.memory()`).
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'mealprep'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await saveSettings(defaultSettings);
      await saveMealSlots(defaultMealSlots);
    },
  );

  // ------------------------------------------------------------- cele

  Future<Settings> loadSettings() async {
    final row = await select(goals).getSingleOrNull();
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
}
