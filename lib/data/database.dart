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
import 'package:uuid/uuid.dart';

import '../logic/defaults.dart';
import '../logic/models.dart';
import '../logic/scaling.dart';
import '../logic/session_plan.dart';
import '../logic/sync_merge.dart';

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
/// łatwo synchronizować z Supabase.
///
/// [id] to numer lokalny (używa go interfejs), [uuid] to globalny
/// identyfikator, ten sam na każdym urządzeniu.
@DataClassName('SessionRow')
@TableIndex(name: 'sessions_uuid', columns: {#uuid}, unique: true)
class Sessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text()();
  DateTimeColumn get firstDay => dateTime()();
  TextColumn get data => text()();

  /// Czas ostatniej zmiany, milisekundy UTC (do scalania przy synchronizacji).
  IntColumn get updatedMs => integer()();

  /// „Nagrobek": sesja usunięta, ale wiersz zostaje, żeby drugie urządzenie
  /// dowiedziało się o usunięciu.
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  /// Zmiana jeszcze niewysłana do Supabase.
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();
}

/// Odhaczenia na liście zakupów. Odznaczenie to `checked = false`
/// (a nie usunięcie wiersza), żeby dało się je zsynchronizować.
@DataClassName('ShoppingCheckRow')
class ShoppingChecks extends Table {
  IntColumn get sessionId => integer()();
  TextColumn get productId => text()();
  BoolColumn get checked => boolean().withDefault(const Constant(true))();
  IntColumn get updatedMs => integer()();
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {sessionId, productId};
}

/// Drobne wartości synchronizacji (klucz → tekst): czas zmiany ustawień,
/// czy są niewysłane, kursory pobierania, czas ostatniej synchronizacji.
@DataClassName('SyncMetaRow')
class SyncMeta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [Goals, MealSlots, Sessions, ShoppingChecks, SyncMeta])
class AppDatabase extends _$AppDatabase {
  /// Bez argumentu: plik `mealprep.sqlite` w folderze danych aplikacji.
  /// W testach podajemy bazę w pamięci (`NativeDatabase.memory()`).
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'mealprep'));

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      // Domyślne ustawienia nie są „zmianą": z czasem 0 przegrają z każdymi
      // prawdziwymi ustawieniami z innego urządzenia.
      await _writeSettings(defaultSettings);
      await _writeMealSlots(defaultMealSlots);
    },
    // Baza z poprzedniej wersji aplikacji: dokładamy tylko to, czego brakuje.
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(sessions);
        await m.createIndex(sessionsUuid);
      } else if (from < 4) {
        // v4: globalny uuid, nagrobki, znacznik „niewysłane", czas w ms.
        await m.alterTable(
          TableMigration(
            sessions,
            columnTransformer: {
              sessions.uuid: const CustomExpression<String>("''"),
              sessions.updatedMs: const CustomExpression<int>(
                'updated_at * 1000',
              ),
            },
            newColumns: [
              sessions.uuid,
              sessions.updatedMs,
              sessions.deleted,
              sessions.dirty,
            ],
          ),
        );
        for (final r in await select(sessions).get()) {
          await (update(sessions)..where((t) => t.id.equals(r.id))).write(
            SessionsCompanion(uuid: Value(_uuid.v4())),
          );
        }
        await m.createIndex(sessionsUuid);
      }
      if (from < 3) {
        await m.createTable(shoppingChecks);
      } else if (from < 4) {
        await m.alterTable(
          TableMigration(
            shoppingChecks,
            columnTransformer: {
              shoppingChecks.updatedMs: const CustomExpression<int>(
                'checked_at * 1000',
              ),
            },
            newColumns: [
              shoppingChecks.updatedMs,
              shoppingChecks.checked,
              shoppingChecks.dirty,
            ],
          ),
        );
      }
      if (from < 4) {
        await m.createTable(syncMeta);
        // Ustawienia z istniejącej bazy to prawdziwe dane: do wysłania.
        await _touchSettings();
      }
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

  /// Zapis ustawień przez użytkownika (oznacza je do wysłania).
  Future<void> saveSettings(Settings s) => transaction(() async {
    await _writeSettings(s);
    await _touchSettings();
  });

  Future<void> _writeSettings(Settings s) => into(goals).insertOnConflictUpdate(
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

  /// Zastępuje całą listę (w jednej transakcji: albo wszystko, albo nic)
  /// i oznacza ustawienia do wysłania.
  Future<void> saveMealSlots(List<MealSlot> slots) => transaction(() async {
    await _writeMealSlots(slots);
    await _touchSettings();
  });

  Future<void> _writeMealSlots(List<MealSlot> slots) => transaction(() async {
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

  /// Wszystkie sesje (bez usuniętych), najnowsze na górze.
  Future<List<SessionPlan>> loadSessions() async =>
      _toPlans(await _sessionsQuery().get());

  /// Strumień sesji: nowa lista po każdej zmianie (np. w edytorze sesji).
  Stream<List<SessionPlan>> watchSessions() =>
      _sessionsQuery().watch().map(_toPlans);

  SimpleSelectStatement<$SessionsTable, SessionRow> _sessionsQuery() =>
      select(sessions)
        ..where((t) => t.deleted.equals(false))
        ..orderBy([(t) => OrderingTerm.desc(t.firstDay)]);

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
      updatedMs: Value(nowMs()),
      dirty: const Value(true),
    );
    if (plan.id == null) {
      final id = await into(sessions)
          .insert(row.copyWith(uuid: Value(_uuid.v4())));
      return plan.copyWith(id: id);
    }
    await (update(sessions)..where((t) => t.id.equals(plan.id!))).write(row);
    return plan;
  }

  /// Usuwa sesję: zostaje „nagrobek" do wysłania, odhaczenia znikają.
  Future<void> deleteSession(int id) => transaction(() async {
    await (delete(shoppingChecks)..where((t) => t.sessionId.equals(id))).go();
    await (update(sessions)..where((t) => t.id.equals(id))).write(
      SessionsCompanion(
        deleted: const Value(true),
        dirty: const Value(true),
        updatedMs: Value(nowMs()),
      ),
    );
  });

  // ---------------------------------------------------- lista zakupów

  /// ID produktów odhaczonych w sesji (strumień, odświeża się po każdej zmianie).
  Stream<Set<String>> watchChecks(int sessionId) =>
      (select(shoppingChecks)..where(
            (t) => t.sessionId.equals(sessionId) & t.checked.equals(true),
          ))
          .watch()
          .map((rows) => {for (final r in rows) r.productId});

  Future<void> setChecked(int sessionId, String productId, bool checked) =>
      into(shoppingChecks).insertOnConflictUpdate(
        ShoppingChecksCompanion.insert(
          sessionId: sessionId,
          productId: productId,
          checked: Value(checked),
          updatedMs: nowMs(),
          dirty: const Value(true),
        ),
      );

  /// Odznacza wszystko w sesji (wiersze zostają z `checked = false`).
  Future<void> clearChecks(int sessionId) =>
      (update(shoppingChecks)..where(
            (t) => t.sessionId.equals(sessionId) & t.checked.equals(true),
          ))
          .write(
            ShoppingChecksCompanion(
              checked: const Value(false),
              dirty: const Value(true),
              updatedMs: Value(nowMs()),
            ),
          );

  // ---------------------------------------------------- synchronizacja
  //
  // Metody dla modułu synchronizacji (lib/data/sync.dart). Zapis danych
  // z serwera NIE oznacza ich jako „niewysłane".

  static const _settingsMs = 'settings_ms';
  static const _settingsDirty = 'settings_dirty';

  Future<String?> getMeta(String key) async => (await (select(
    syncMeta,
  )..where((t) => t.key.equals(key))).getSingleOrNull())?.value;

  Future<void> setMeta(String key, String? value) async {
    if (value == null) {
      await (delete(syncMeta)..where((t) => t.key.equals(key))).go();
    } else {
      await into(syncMeta).insertOnConflictUpdate(
        SyncMetaCompanion.insert(key: key, value: value),
      );
    }
  }

  Stream<String?> watchMeta(String key) => (select(
    syncMeta,
  )..where((t) => t.key.equals(key))).watchSingleOrNull().map((r) => r?.value);

  Future<void> _touchSettings() async {
    await setMeta(_settingsMs, '${nowMs()}');
    await setMeta(_settingsDirty, '1');
  }

  /// Liczba niewysłanych zmian (strumień). Moduł synchronizacji wysyła,
  /// gdy jest > 0.
  Stream<int> watchPendingCount() => customSelect(
    'SELECT '
    '(SELECT COUNT(*) FROM sessions WHERE dirty = 1) + '
    '(SELECT COUNT(*) FROM shopping_checks WHERE dirty = 1) + '
    "(SELECT COUNT(*) FROM sync_meta WHERE key = '$_settingsDirty' "
    "AND value = '1') AS n",
    readsFrom: {sessions, shoppingChecks, syncMeta},
  ).watchSingle().map((r) => r.read<int>('n'));

  /// Ustawienia do wysłania albo `null`, gdy nic się nie zmieniło.
  Future<RemoteSettings?> pendingSettings() async {
    if (await getMeta(_settingsDirty) != '1') return null;
    return RemoteSettings(
      data: settingsToJson(await loadSettings(), await loadMealSlots()),
      updatedMs: int.parse(await getMeta(_settingsMs) ?? '0'),
    );
  }

  /// Po wysłaniu: zdejmuje znacznik, o ile w międzyczasie nie było zmiany.
  Future<void> markSettingsSent(int updatedMs) => transaction(() async {
    if (await getMeta(_settingsMs) == '$updatedMs') {
      await setMeta(_settingsDirty, null);
    }
  });

  /// Wstawia ustawienia z serwera, jeśli są nowsze. Zwraca, czy wstawiło.
  Future<bool> applyRemoteSettings(RemoteSettings r) => transaction(() async {
    final localMs = int.tryParse(await getMeta(_settingsMs) ?? '');
    if (!remoteWins(localMs: localMs, remoteMs: r.updatedMs)) return false;
    final (s, slots) = settingsFromJson(r.data);
    await _writeSettings(s);
    await _writeMealSlots(slots);
    await setMeta(_settingsMs, '${r.updatedMs}');
    await setMeta(_settingsDirty, null);
    return true;
  });

  Future<List<RemoteSession>> pendingSessions() async => [
    for (final r in await (select(
      sessions,
    )..where((t) => t.dirty.equals(true))).get())
      RemoteSession(
        uuid: r.uuid,
        data: jsonDecode(r.data) as Map<String, dynamic>,
        deleted: r.deleted,
        updatedMs: r.updatedMs,
      ),
  ];

  Future<void> markSessionsSent(List<RemoteSession> sent) =>
      transaction(() async {
        for (final s in sent) {
          await (update(sessions)..where(
                (t) => t.uuid.equals(s.uuid) & t.updatedMs.equals(s.updatedMs),
              ))
              .write(const SessionsCompanion(dirty: Value(false)));
        }
      });

  Future<void> applyRemoteSessions(List<RemoteSession> rows) =>
      transaction(() async {
        for (final r in rows) {
          final local = await (select(
            sessions,
          )..where((t) => t.uuid.equals(r.uuid))).getSingleOrNull();
          if (!remoteWins(localMs: local?.updatedMs, remoteMs: r.updatedMs)) {
            continue;
          }
          final row = SessionsCompanion(
            uuid: Value(r.uuid),
            firstDay: Value(DateTime.parse(r.data['first_day'] as String)),
            data: Value(jsonEncode(r.data)),
            updatedMs: Value(r.updatedMs),
            deleted: Value(r.deleted),
            dirty: const Value(false),
          );
          if (local == null) {
            await into(sessions).insert(row);
          } else {
            await (update(
              sessions,
            )..where((t) => t.id.equals(local.id))).write(row);
            if (r.deleted) {
              await (delete(
                shoppingChecks,
              )..where((t) => t.sessionId.equals(local.id))).go();
            }
          }
        }
      });

  Future<List<RemoteCheck>> pendingChecks() async {
    final q = select(shoppingChecks).join([
      innerJoin(sessions, sessions.id.equalsExp(shoppingChecks.sessionId)),
    ])..where(shoppingChecks.dirty.equals(true));
    return [
      for (final row in await q.get())
        RemoteCheck(
          sessionUuid: row.readTable(sessions).uuid,
          productId: row.readTable(shoppingChecks).productId,
          checked: row.readTable(shoppingChecks).checked,
          updatedMs: row.readTable(shoppingChecks).updatedMs,
        ),
    ];
  }

  Future<void> markChecksSent(List<RemoteCheck> sent) => transaction(() async {
    final ids = await _sessionIdsByUuid();
    for (final c in sent) {
      final id = ids[c.sessionUuid];
      if (id == null) continue;
      await (update(shoppingChecks)..where(
            (t) =>
                t.sessionId.equals(id) &
                t.productId.equals(c.productId) &
                t.updatedMs.equals(c.updatedMs),
          ))
          .write(const ShoppingChecksCompanion(dirty: Value(false)));
    }
  });

  /// Odhaczenia z serwera. Pomija te z sesji nieznanych albo usuniętych.
  Future<void> applyRemoteChecks(List<RemoteCheck> rows) =>
      transaction(() async {
        final ids = await _sessionIdsByUuid(includeDeleted: false);
        for (final r in rows) {
          final sessionId = ids[r.sessionUuid];
          if (sessionId == null) continue;
          final local =
              await (select(shoppingChecks)..where(
                    (t) =>
                        t.sessionId.equals(sessionId) &
                        t.productId.equals(r.productId),
                  ))
                  .getSingleOrNull();
          if (!remoteWins(localMs: local?.updatedMs, remoteMs: r.updatedMs)) {
            continue;
          }
          await into(shoppingChecks).insertOnConflictUpdate(
            ShoppingChecksCompanion.insert(
              sessionId: sessionId,
              productId: r.productId,
              checked: Value(r.checked),
              updatedMs: r.updatedMs,
              dirty: const Value(false),
            ),
          );
        }
      });

  Future<Map<String, int>> _sessionIdsByUuid({
    bool includeDeleted = true,
  }) async {
    final q = select(sessions);
    if (!includeDeleted) q.where((t) => t.deleted.equals(false));
    return {for (final r in await q.get()) r.uuid: r.id};
  }

  /// Wszystko jako „niewysłane" (np. po zalogowaniu na nowe konto).
  Future<void> markAllPending() => transaction(() async {
    await update(sessions).write(const SessionsCompanion(dirty: Value(true)));
    await update(shoppingChecks)
        .write(const ShoppingChecksCompanion(dirty: Value(true)));
    if ((await getMeta(_settingsMs) ?? '0') != '0') {
      await setMeta(_settingsDirty, '1');
    }
  });
}

const _uuid = Uuid();
