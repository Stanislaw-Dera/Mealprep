/// Synchronizacja lokalnej bazy z Supabase.
///
/// Trzy warstwy, żeby dało się testować bez sieci:
/// * [SyncRemote]: „serwer" (w aplikacji Supabase, w testach atrapa w pamięci),
/// * [SyncEngine]: jedna wysyłka i jedno pobranie (scalanie w `database.dart`
///   według zasad z `logic/sync_merge.dart`),
/// * [SyncController]: kiedy synchronizować (po zalogowaniu, po każdej
///   lokalnej zmianie, po zmianie na serwerze, po powrocie do aplikacji),
///   stan dla ekranu Ustawień i komunikaty błędów po polsku.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../logic/sync_merge.dart';
import 'database.dart';

/// Serwer z danymi użytkownika.
abstract class SyncRemote {
  /// Wiersze zmienione na serwerze po [since] (`null` = wszystkie).
  Future<RemoteSettings?> fetchSettings(String? since);
  Future<List<RemoteSession>> fetchSessions(String? since);
  Future<List<RemoteCheck>> fetchChecks(String? since);

  /// Wysyłka; serwer sam pomija wersje starsze od swoich.
  Future<void> pushSettings(RemoteSettings s);
  Future<void> pushSessions(List<RemoteSession> rows);
  Future<void> pushChecks(List<RemoteCheck> rows);

  /// Nasłuch zmian na serwerze (Realtime). Zwraca funkcję kończącą nasłuch.
  void Function() listen(void Function() onChange);
}

/// Logowanie (w aplikacji Supabase Auth).
abstract class SyncAuth {
  /// E-mail zalogowanego użytkownika albo `null`.
  String? get email;

  /// Zdarzenie po każdym zalogowaniu i wylogowaniu.
  Stream<void> get changes;

  Future<void> signIn(String email, String password);
  Future<void> signOut();
}

class SyncEngine {
  SyncEngine(this.db, this.remote);

  final AppDatabase db;
  final SyncRemote remote;

  static const _cursorSettings = 'cursor_settings';
  static const _cursorSessions = 'cursor_sessions';
  static const _cursorChecks = 'cursor_checks';

  /// Wysyła wszystkie niewysłane zmiany. Sesje przed odhaczeniami,
  /// bo odhaczenia wskazują na sesje.
  Future<void> push() async {
    final settings = await db.pendingSettings();
    if (settings != null) {
      await remote.pushSettings(settings);
      await db.markSettingsSent(settings.updatedMs);
    }
    final sessions = await db.pendingSessions();
    if (sessions.isNotEmpty) {
      await remote.pushSessions(sessions);
      await db.markSessionsSent(sessions);
    }
    final checks = await db.pendingChecks();
    if (checks.isNotEmpty) {
      await remote.pushChecks(checks);
      await db.markChecksSent(checks);
    }
  }

  /// Pobiera zmiany od ostatniego pobrania. Zwraca, czy zmieniły się
  /// ustawienia (ekran Ustawień czyta je raz, więc musi wiedzieć).
  Future<bool> pull() async {
    var settingsChanged = false;
    final cs = await db.getMeta(_cursorSettings);
    final settings = await remote.fetchSettings(pullSince(cs));
    if (settings != null) {
      settingsChanged = await db.applyRemoteSettings(settings);
      await db.setMeta(_cursorSettings, laterCursor(cs, settings.syncedAt));
    }

    final cses = await db.getMeta(_cursorSessions);
    final sessions = await remote.fetchSessions(pullSince(cses));
    await db.applyRemoteSessions(sessions);
    await db.setMeta(
      _cursorSessions,
      sessions.fold<String?>(cses, (c, r) => laterCursor(c, r.syncedAt)),
    );

    final cc = await db.getMeta(_cursorChecks);
    final checks = await remote.fetchChecks(pullSince(cc));
    await db.applyRemoteChecks(checks);
    await db.setMeta(
      _cursorChecks,
      checks.fold<String?>(cc, (c, r) => laterCursor(c, r.syncedAt)),
    );
    return settingsChanged;
  }

  /// Pełna synchronizacja: najpierw wysyłka, potem pobranie.
  Future<bool> syncAll() async {
    await push();
    return pull();
  }

  /// Zapomina kursory, żeby następne pobranie wzięło wszystko z serwera.
  Future<void> resetCursors() async {
    for (final k in [_cursorSettings, _cursorSessions, _cursorChecks]) {
      await db.setMeta(k, null);
    }
  }
}

/// Stan synchronizacji dla interfejsu.
class SyncController extends ChangeNotifier {
  SyncController({
    required this.db,
    required this.auth,
    required SyncRemote remote,
    this.pushDelay = const Duration(seconds: 1),
    this.retryDelay = const Duration(seconds: 30),
  }) : _engine = SyncEngine(db, remote),
       _remote = remote;

  final AppDatabase db;
  final SyncAuth auth;
  final SyncEngine _engine;
  final SyncRemote _remote;

  /// Odczekanie przed wysyłką (kilka szybkich zmian idzie razem).
  final Duration pushDelay;

  /// Po błędzie (np. brak sieci) próbujemy znowu po tym czasie.
  final Duration retryDelay;

  static const _lastSyncKey = 'last_sync';
  static const _userKey = 'user_email';

  bool _busy = false;
  bool _again = false;
  String? _error;
  DateTime? _lastSync;
  int _pending = 0;
  int _settingsVersion = 0;

  Timer? _timer;
  void Function()? _stopListening;
  final _subs = <StreamSubscription<Object?>>[];

  String? get email => auth.email;
  bool get signedIn => auth.email != null;
  bool get busy => _busy;
  String? get error => _error;
  DateTime? get lastSync => _lastSync;

  /// Liczba zmian czekających na wysłanie.
  int get pending => _pending;

  /// Rośnie, gdy z serwera przyszły nowe ustawienia.
  int get settingsVersion => _settingsVersion;

  /// Start: nasłuch logowania i lokalnych zmian. Wywołaj raz.
  Future<void> start() async {
    final last = await db.getMeta(_lastSyncKey);
    _lastSync = last == null ? null : DateTime.parse(last).toLocal();
    _subs.add(auth.changes.listen((_) => _authChanged()));
    _subs.add(
      db.watchPendingCount().listen((n) {
        _pending = n;
        notifyListeners();
        if (n > 0 && signedIn) _schedule(pushDelay);
      }),
    );
    await _authChanged();
  }

  Future<void> _authChanged() async {
    _stopListening?.call();
    _stopListening = null;
    final email = auth.email;
    if (email != null) {
      // Inne konto niż ostatnio (albo pierwsze logowanie na tym urządzeniu):
      // pobierz wszystko i wyślij wszystkie lokalne dane.
      if (await db.getMeta(_userKey) != email) {
        await _engine.resetCursors();
        await db.markAllPending();
        await db.setMeta(_userKey, email);
      }
      _stopListening = _remote.listen(() => _schedule(Duration.zero));
      unawaited(syncNow());
    } else {
      _timer?.cancel();
      _error = null;
    }
    notifyListeners();
  }

  void _schedule(Duration delay) {
    _timer?.cancel();
    _timer = Timer(delay, syncNow);
  }

  /// Wysyła i pobiera. Wywołanie w trakcie synchronizacji powtórzy ją po końcu.
  Future<void> syncNow() async {
    if (!signedIn) return;
    if (_busy) {
      _again = true;
      return;
    }
    _timer?.cancel();
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      if (await _engine.syncAll()) _settingsVersion++;
      _lastSync = DateTime.now();
      await db.setMeta(_lastSyncKey, _lastSync!.toUtc().toIso8601String());
    } catch (e) {
      _error = describeError(e);
      _schedule(retryDelay);
    } finally {
      _busy = false;
      notifyListeners();
    }
    if (_again) {
      _again = false;
      await syncNow();
    }
  }

  /// Logowanie. Zwraca komunikat błędu po polsku albo `null`, gdy się udało.
  Future<String?> signIn(String email, String password) async {
    try {
      await auth.signIn(email.trim(), password);
      return null;
    } catch (e) {
      return describeError(e);
    }
  }

  Future<void> signOut() async {
    await auth.signOut();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopListening?.call();
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }
}

/// Komunikat błędu dla użytkownika.
String describeError(Object e) {
  final text = e.toString();
  final lower = text.toLowerCase();
  if (e is SocketException ||
      e is TimeoutException ||
      lower.contains('socketexception') ||
      lower.contains('failed host lookup') ||
      lower.contains('connection')) {
    return 'Brak połączenia z serwerem. Spróbuję ponownie za chwilę.';
  }
  if (lower.contains('invalid login credentials')) {
    return 'Zły e-mail albo hasło.';
  }
  if (lower.contains('email not confirmed')) {
    return 'Adres e-mail nie jest potwierdzony (Supabase → Authentication → Users).';
  }
  if (lower.contains('jwt') || lower.contains('refresh token')) {
    return 'Sesja logowania wygasła. Wyloguj się i zaloguj ponownie.';
  }
  if (lower.contains('pgrst205') || lower.contains('schema cache')) {
    return 'Brak tabel w Supabase. Wklej supabase/schema.sql w SQL Editor.';
  }
  return 'Błąd synchronizacji: $text';
}
