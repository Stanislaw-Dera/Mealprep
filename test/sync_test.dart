import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mealprep/data/database.dart';
import 'package:mealprep/data/sync.dart';
import 'package:mealprep/logic/defaults.dart';
import 'package:mealprep/logic/models.dart';
import 'package:mealprep/logic/scaling.dart';
import 'package:mealprep/logic/session_plan.dart';
import 'package:mealprep/logic/sync_merge.dart';

/// Serwer w pamięci, który zachowuje się jak Supabase ze `schema.sql`:
/// starsza wersja nie nadpisuje nowszej, każdy zapis dostaje `synced_at`.
class FakeRemote implements SyncRemote {
  RemoteSettings? settings;
  final sessions = <String, RemoteSession>{};
  final checks = <String, RemoteCheck>{};
  var _clock = DateTime.utc(2026, 11, 10, 12);
  final _listeners = <void Function()>[];
  bool offline = false;

  String _tick() =>
      (_clock = _clock.add(const Duration(seconds: 1))).toIso8601String();

  bool _newer(String? since, String? syncedAt) =>
      since == null || DateTime.parse(syncedAt!).isAfter(DateTime.parse(since));

  void _check() {
    if (offline) throw const SocketException('Failed host lookup');
  }

  void _changed() {
    for (final l in [..._listeners]) {
      l();
    }
  }

  @override
  Future<RemoteSettings?> fetchSettings(String? since) async {
    _check();
    final s = settings;
    return s != null && _newer(since, s.syncedAt) ? s : null;
  }

  @override
  Future<List<RemoteSession>> fetchSessions(String? since) async {
    _check();
    return [
      for (final s in sessions.values)
        if (_newer(since, s.syncedAt)) s,
    ];
  }

  @override
  Future<List<RemoteCheck>> fetchChecks(String? since) async {
    _check();
    return [
      for (final c in checks.values)
        if (_newer(since, c.syncedAt)) c,
    ];
  }

  @override
  Future<void> pushSettings(RemoteSettings s) async {
    _check();
    if (settings != null && s.updatedMs <= settings!.updatedMs) return;
    settings = RemoteSettings(
      data: s.data,
      updatedMs: s.updatedMs,
      syncedAt: _tick(),
    );
    _changed();
  }

  @override
  Future<void> pushSessions(List<RemoteSession> rows) async {
    _check();
    for (final r in rows) {
      final old = sessions[r.uuid];
      if (old != null && r.updatedMs <= old.updatedMs) continue;
      sessions[r.uuid] = RemoteSession(
        uuid: r.uuid,
        data: r.data,
        deleted: r.deleted,
        updatedMs: r.updatedMs,
        syncedAt: _tick(),
      );
    }
    _changed();
  }

  @override
  Future<void> pushChecks(List<RemoteCheck> rows) async {
    _check();
    for (final r in rows) {
      final key = '${r.sessionUuid}/${r.productId}';
      final old = checks[key];
      if (old != null && r.updatedMs <= old.updatedMs) continue;
      checks[key] = RemoteCheck(
        sessionUuid: r.sessionUuid,
        productId: r.productId,
        checked: r.checked,
        updatedMs: r.updatedMs,
        syncedAt: _tick(),
      );
    }
    _changed();
  }

  @override
  void Function() listen(void Function() onChange) {
    _listeners.add(onChange);
    return () => _listeners.remove(onChange);
  }
}

class FakeAuth implements SyncAuth {
  @override
  String? email;
  final _changes = StreamController<void>.broadcast();

  @override
  Stream<void> get changes => _changes.stream;

  @override
  Future<void> signIn(String email, String password) async {
    if (password != 'dobre') throw Exception('Invalid login credentials');
    this.email = email;
    _changes.add(null);
  }

  @override
  Future<void> signOut() async {
    email = null;
    _changes.add(null);
  }
}

SessionPlan newPlan(DateTime day) =>
    SessionPlan.create(firstDay: day, dayCount: 3, slots: defaultMealSlots);

/// Czeka, aż zegar przesunie się o 2 ms (żeby kolejne zmiany miały
/// różne czasy).
Future<void> tick() => Future<void>.delayed(const Duration(milliseconds: 2));

void main() {
  group('zasady scalania', () {
    test('nowsza wygrywa, równa zostaje lokalna, brak lokalnej = z serwera', () {
      expect(remoteWins(localMs: 100, remoteMs: 200), isTrue);
      expect(remoteWins(localMs: 200, remoteMs: 100), isFalse);
      expect(remoteWins(localMs: 200, remoteMs: 200), isFalse);
      expect(remoteWins(localMs: null, remoteMs: 0), isTrue);
    });

    test('kursor cofa się o minutę i wybiera nowszy czas', () {
      expect(pullSince(null), isNull);
      expect(
        pullSince('2026-11-10T12:00:00.000Z'),
        '2026-11-10T11:59:00.000Z',
      );
      expect(
        laterCursor('2026-11-10T12:00:00+00:00', '2026-11-10T11:00:00Z'),
        '2026-11-10T12:00:00+00:00',
      );
      expect(laterCursor(null, 'x'), 'x');
    });

    test('czas w ms ↔ ISO bez utraty dokładności', () {
      const ms = 1794312000123;
      expect(msFromIso(isoFromMs(ms)), ms);
      expect(msFromIso('2026-11-10T12:00:00.123+00:00'), ms);
    });

    test('ustawienia jako JSON w obie strony', () {
      const s = Settings(
        target: Macros(kcal: 3100, p: 190, f: 95, c: 375),
        trainingExtraKcal: 300,
        trainingExtraFrom: Macro.f,
      );
      final (back, slots) = settingsFromJson(
        settingsToJson(s, defaultMealSlots),
      );
      expect(back.target.toJson(), s.target.toJson());
      expect(back.trainingExtraFrom, Macro.f);
      expect(slots, defaultMealSlots);
    });
  });

  group('silnik synchronizacji (dwa urządzenia, serwer w pamięci)', () {
    late AppDatabase mac;
    late AppDatabase phone;
    late FakeRemote server;
    late SyncEngine macSync;
    late SyncEngine phoneSync;

    setUp(() {
      mac = AppDatabase(NativeDatabase.memory());
      phone = AppDatabase(NativeDatabase.memory());
      server = FakeRemote();
      macSync = SyncEngine(mac, server);
      phoneSync = SyncEngine(phone, server);
    });
    tearDown(() async {
      await mac.close();
      await phone.close();
    });

    test('domyślne ustawienia nowej bazy nie są wysyłane', () async {
      expect(await mac.pendingSettings(), isNull);
      await macSync.syncAll();
      expect(server.settings, isNull);
    });

    test('sesja, ustawienia i odhaczenia przechodzą na drugie urządzenie', () async {
      await mac.saveSettings(
        const Settings(target: Macros(kcal: 3200, p: 200, f: 90, c: 400)),
      );
      final s = await mac.saveSession(
        newPlan(DateTime(2026, 11, 9)).withRecipe('Obiad', 'chili-con-carne'),
      );
      await mac.setChecked(s.id!, 'cebula', true);
      await macSync.syncAll();
      expect(await mac.watchPendingCount().first, 0);

      expect(await phoneSync.syncAll(), isTrue); // ustawienia się zmieniły
      expect((await phone.loadSettings()).target.kcal, 3200);
      final sessions = await phone.loadSessions();
      expect(sessions.single.recipes, {'Obiad': 'chili-con-carne'});
      expect(await phone.watchChecks(sessions.single.id!).first, {'cebula'});
      // Dane z serwera nie są „niewysłane".
      expect(await phone.watchPendingCount().first, 0);
    });

    test('konflikt: wygrywa nowsza zmiana, bez względu na kolejność wysyłki', () async {
      final s = await mac.saveSession(newPlan(DateTime(2026, 11, 9)));
      await macSync.syncAll();
      await phoneSync.syncAll();
      final onPhone = (await phone.loadSessions()).single;

      // Najpierw zmiana na Macu (starsza), potem na telefonie (nowsza)...
      await mac.saveSession(s.withRecipe('Obiad', 'starsze'));
      await tick();
      await phone.saveSession(onPhone.withRecipe('Obiad', 'nowsze'));
      // ...ale telefon wysyła pierwszy.
      await phoneSync.syncAll();
      await macSync.syncAll();
      await phoneSync.syncAll();

      expect((await mac.loadSessions()).single.recipes['Obiad'], 'nowsze');
      expect((await phone.loadSessions()).single.recipes['Obiad'], 'nowsze');
    });

    test('nagrobek: usunięta sesja znika z drugiego urządzenia', () async {
      final s = await mac.saveSession(newPlan(DateTime(2026, 11, 9)));
      await mac.setChecked(s.id!, 'cebula', true);
      await macSync.syncAll();
      await phoneSync.syncAll();
      expect(await phone.loadSessions(), hasLength(1));

      await mac.deleteSession(s.id!);
      expect(await mac.loadSessions(), isEmpty);
      await macSync.syncAll();
      expect(server.sessions.values.single.deleted, isTrue);

      await phoneSync.syncAll();
      expect(await phone.loadSessions(), isEmpty);
      expect(await phone.select(phone.shoppingChecks).get(), isEmpty);
    });

    test('odznaczenie i „wyczyść" też się synchronizują', () async {
      final s = await mac.saveSession(newPlan(DateTime(2026, 11, 9)));
      await mac.setChecked(s.id!, 'cebula', true);
      await mac.setChecked(s.id!, 'ryz-bialy', true);
      await macSync.syncAll();
      await phoneSync.syncAll();
      final id = (await phone.loadSessions()).single.id!;
      expect(await phone.watchChecks(id).first, {'cebula', 'ryz-bialy'});

      await tick();
      await mac.setChecked(s.id!, 'cebula', false);
      await macSync.syncAll();
      await phoneSync.syncAll();
      expect(await phone.watchChecks(id).first, {'ryz-bialy'});

      await tick();
      await phone.clearChecks(id);
      await phoneSync.syncAll();
      await macSync.syncAll();
      expect(await mac.watchChecks(s.id!).first, isEmpty);
    });

    test('zmiana w trakcie wysyłki zostaje oznaczona do wysłania', () async {
      final s = await mac.saveSession(newPlan(DateTime(2026, 11, 9)));
      final pending = await mac.pendingSessions();
      await tick();
      await mac.saveSession(s.withRecipe('Obiad', 'chili-con-carne'));
      await server.pushSessions(pending);
      await mac.markSessionsSent(pending); // wysłana była starsza wersja
      expect(await mac.watchPendingCount().first, 1);
    });

    test('bez sieci zmiany czekają i idą po powrocie', () async {
      await mac.saveSession(newPlan(DateTime(2026, 11, 9)));
      server.offline = true;
      await expectLater(macSync.syncAll(), throwsA(isA<SocketException>()));
      expect(await mac.watchPendingCount().first, 1);
      server.offline = false;
      await macSync.syncAll();
      expect(await mac.watchPendingCount().first, 0);
      expect(server.sessions, hasLength(1));
    });

    test('drugie pobranie bierze tylko nowe zmiany', () async {
      await mac.saveSession(newPlan(DateTime(2026, 11, 9)));
      await macSync.syncAll();
      await phoneSync.pull();
      expect(
        await server.fetchSessions(
          pullSince(await phone.getMeta('cursor_sessions')),
        ),
        hasLength(1), // ta sama, w minutowym zakładzie
      );
      // Zegar serwera idzie dalej o więcej niż minutę.
      for (var i = 0; i < 70; i++) {
        server._tick();
      }
      await mac.saveSession(newPlan(DateTime(2026, 11, 12)));
      await macSync.syncAll();
      await phoneSync.pull();
      expect(await phone.loadSessions(), hasLength(2));
      // Kursor przesunął się: stara sesja (sprzed ponad minuty) już nie wraca.
      final fresh = await server.fetchSessions(
        pullSince(await phone.getMeta('cursor_sessions')),
      );
      expect(fresh.single.data['first_day'], '2026-11-12');
    });
  });

  group('SyncController', () {
    late AppDatabase db;
    late FakeRemote server;
    late FakeAuth auth;
    late SyncController sync;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      server = FakeRemote();
      auth = FakeAuth();
      sync = SyncController(
        db: db,
        auth: auth,
        remote: server,
        pushDelay: Duration.zero,
        retryDelay: const Duration(hours: 1),
      );
      await sync.start();
    });
    tearDown(() async {
      sync.dispose();
      await db.close();
    });

    Future<void> idle() async {
      for (var i = 0; i < 20; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
        if (!sync.busy) break;
      }
    }

    test('złe hasło daje komunikat po polsku', () async {
      expect(await sync.signIn('a@b.pl', 'złe'), 'Zły e-mail albo hasło.');
      expect(sync.signedIn, isFalse);
    });

    test('pierwsze logowanie wysyła istniejące dane, potem każdą zmianę', () async {
      await db.saveSession(newPlan(DateTime(2026, 11, 9)));
      expect(await sync.signIn('a@b.pl', 'dobre'), isNull);
      await idle();
      expect(server.sessions, hasLength(1));
      expect(sync.lastSync, isNotNull);

      await db.saveSession(newPlan(DateTime(2026, 11, 12)));
      await idle();
      await idle();
      expect(server.sessions, hasLength(2));
      expect(sync.pending, 0);
    });

    test('błąd sieci pokazuje komunikat', () async {
      server.offline = true;
      await sync.signIn('a@b.pl', 'dobre');
      await idle();
      expect(sync.error, contains('Brak połączenia'));
    });
  });
}
