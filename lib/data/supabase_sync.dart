/// [SyncRemote] i [SyncAuth] na Supabase (pakiet `supabase_flutter`).
///
/// Adres projektu i klucz publishable przychodzą z `supabase.json` przy
/// budowaniu (`--dart-define-from-file=supabase.json`). Bez nich aplikacja
/// działa bez synchronizacji.
library;

import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../logic/sync_merge.dart';
import 'sync.dart';

const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

/// Czy aplikację zbudowano z danymi projektu Supabase.
bool get supabaseConfigured =>
    supabaseUrl.startsWith('https://') && supabaseKey.isNotEmpty;

Future<void> initSupabase() =>
    Supabase.initialize(url: supabaseUrl, publishableKey: supabaseKey);

class SupabaseAuth implements SyncAuth {
  SupabaseAuth(this.client);
  final SupabaseClient client;

  @override
  String? get email => client.auth.currentUser?.email;

  // Tylko zalogowanie i wylogowanie (odświeżanie tokenu nas nie interesuje).
  @override
  Stream<void> get changes => client.auth.onAuthStateChange
      .where(
        (s) =>
            s.event == AuthChangeEvent.signedIn ||
            s.event == AuthChangeEvent.signedOut,
      )
      .map((_) {});

  @override
  Future<void> signIn(String email, String password) =>
      client.auth.signInWithPassword(email: email, password: password);

  @override
  Future<void> signOut() => client.auth.signOut();
}

class SupabaseRemote implements SyncRemote {
  SupabaseRemote(this.client);
  final SupabaseClient client;

  /// Tyle wierszy na zapytanie (PostgREST oddaje najwyżej 1000).
  static const _page = 500;

  static const _key = {
    'settings': 'user_id',
    'sessions': 'id',
    'shopping_checks': 'product_id',
  };

  String get _userId => client.auth.currentUser!.id;

  /// Wszystkie wiersze tabeli zmienione po [since], stronami.
  Future<List<Map<String, dynamic>>> _fetch(String table, String? since) async {
    final out = <Map<String, dynamic>>[];
    for (var from = 0; ; from += _page) {
      var q = client.from(table).select();
      if (since != null) q = q.gt('synced_at', since);
      // Stała kolejność, żeby strony się nie nakładały.
      final rows = await q
          .order('synced_at', ascending: true)
          .order(_key[table]!, ascending: true)
          .range(from, from + _page - 1);
      out.addAll(rows);
      if (rows.length < _page) return out;
    }
  }

  @override
  Future<RemoteSettings?> fetchSettings(String? since) async {
    final rows = await _fetch('settings', since);
    if (rows.isEmpty) return null;
    final r = rows.first;
    return RemoteSettings(
      data: r['data'] as Map<String, dynamic>,
      updatedMs: msFromIso(r['updated_at'] as String),
      syncedAt: r['synced_at'] as String,
    );
  }

  @override
  Future<List<RemoteSession>> fetchSessions(String? since) async => [
    for (final r in await _fetch('sessions', since))
      RemoteSession(
        uuid: r['id'] as String,
        data: r['data'] as Map<String, dynamic>,
        deleted: r['deleted'] as bool,
        updatedMs: msFromIso(r['updated_at'] as String),
        syncedAt: r['synced_at'] as String,
      ),
  ];

  @override
  Future<List<RemoteCheck>> fetchChecks(String? since) async => [
    for (final r in await _fetch('shopping_checks', since))
      RemoteCheck(
        sessionUuid: r['session_id'] as String,
        productId: r['product_id'] as String,
        checked: r['checked'] as bool,
        updatedMs: msFromIso(r['updated_at'] as String),
        syncedAt: r['synced_at'] as String,
      ),
  ];

  @override
  Future<void> pushSettings(RemoteSettings s) =>
      client.from('settings').upsert({
        'user_id': _userId,
        'data': s.data,
        'updated_at': isoFromMs(s.updatedMs),
      }, onConflict: 'user_id');

  @override
  Future<void> pushSessions(List<RemoteSession> rows) =>
      client.from('sessions').upsert([
        for (final r in rows)
          {
            'id': r.uuid,
            'user_id': _userId,
            'first_day': r.data['first_day'],
            'data': r.data,
            'deleted': r.deleted,
            'updated_at': isoFromMs(r.updatedMs),
          },
      ], onConflict: 'id');

  @override
  Future<void> pushChecks(List<RemoteCheck> rows) async {
    for (var i = 0; i < rows.length; i += _page) {
      await client.from('shopping_checks').upsert([
        for (final r in rows.skip(i).take(_page))
          {
            'user_id': _userId,
            'session_id': r.sessionUuid,
            'product_id': r.productId,
            'checked': r.checked,
            'updated_at': isoFromMs(r.updatedMs),
          },
      ], onConflict: 'session_id,product_id');
    }
  }

  @override
  void Function() listen(void Function() onChange) {
    final channel = client.channel('mealprep-sync');
    for (final table in ['sessions', 'shopping_checks', 'settings']) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: table,
        callback: (_) => onChange(),
      );
    }
    channel.subscribe();
    return () => unawaited(client.removeChannel(channel));
  }
}
