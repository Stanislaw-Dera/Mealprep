// Atrapy serwera i logowania do testów synchronizacji (bez sieci).
import 'dart:async';
import 'dart:io';

import 'package:mealprep/data/sync.dart';
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

  String tick() =>
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
      syncedAt: tick(),
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
        syncedAt: tick(),
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
        syncedAt: tick(),
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
