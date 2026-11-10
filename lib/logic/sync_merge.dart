/// Zasady scalania przy synchronizacji (czysty Dart, bez bazy i sieci).
///
/// Każdy wiersz ma czas ostatniej zmiany w milisekundach UTC (`updatedMs`).
/// Przy konflikcie wygrywa nowsza zmiana („last write wins"). Ta sama zasada
/// działa w Supabase (wyzwalacz w `supabase/schema.sql`).
library;

import 'models.dart';
import 'scaling.dart';

/// Czas „teraz" w formacie używanym przy synchronizacji.
int nowMs() => DateTime.now().toUtc().millisecondsSinceEpoch;

/// Czy wersja z serwera ma zastąpić lokalną. `localMs == null`: wiersza
/// lokalnie nie ma. Przy równym czasie zostaje lokalna (to ta sama zmiana).
bool remoteWins({required int? localMs, required int remoteMs}) =>
    localMs == null || remoteMs > localMs;

/// Od jakiego `synced_at` pobierać zmiany. Cofamy się o minutę względem
/// ostatnio widzianego, bo zapis, który zaczął się wcześniej, mógł trafić do
/// bazy chwilę później. Ponowne pobranie tego samego nic nie psuje.
String? pullSince(String? cursor) {
  if (cursor == null) return null;
  return DateTime.parse(cursor)
      .toUtc()
      .subtract(const Duration(minutes: 1))
      .toIso8601String();
}

/// Nowszy z dwóch kursorów (czasów `synced_at` z serwera).
String? laterCursor(String? a, String? b) {
  if (a == null) return b;
  if (b == null) return a;
  return DateTime.parse(a).isAfter(DateTime.parse(b)) ? a : b;
}

int msFromIso(String iso) => DateTime.parse(iso).toUtc().millisecondsSinceEpoch;

String isoFromMs(int ms) =>
    DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toIso8601String();

/// Ustawienia (cele i posiłki) jako jeden obiekt, jak w tabeli `settings`.
Map<String, dynamic> settingsToJson(Settings s, List<MealSlot> slots) => {
  'goals': {
    'target': s.target.toJson(),
    'training_extra_kcal': s.trainingExtraKcal,
    'training_extra_from': s.trainingExtraFrom.name,
  },
  'meal_slots': [
    for (final m in slots) {'name': m.name, 'prep': m.prep},
  ],
};

(Settings, List<MealSlot>) settingsFromJson(Map<String, dynamic> j) => (
  Settings.fromJson(j['goals'] as Map<String, dynamic>),
  [
    for (final m in j['meal_slots'] as List)
      MealSlot(name: m['name'] as String, prep: m['prep'] as bool),
  ],
);

/// Wiersz `settings` w Supabase.
class RemoteSettings {
  const RemoteSettings({
    required this.data,
    required this.updatedMs,
    this.syncedAt,
  });
  final Map<String, dynamic> data;
  final int updatedMs;

  /// Czas zapisu na serwerze (`null` przy wysyłce).
  final String? syncedAt;
}

/// Wiersz `sessions` w Supabase.
class RemoteSession {
  const RemoteSession({
    required this.uuid,
    required this.data,
    required this.deleted,
    required this.updatedMs,
    this.syncedAt,
  });
  final String uuid;

  /// Plan jak w `SessionPlan.toJson()`.
  final Map<String, dynamic> data;
  final bool deleted;
  final int updatedMs;
  final String? syncedAt;
}

/// Wiersz `shopping_checks` w Supabase.
class RemoteCheck {
  const RemoteCheck({
    required this.sessionUuid,
    required this.productId,
    required this.checked,
    required this.updatedMs,
    this.syncedAt,
  });
  final String sessionUuid;
  final String productId;
  final bool checked;
  final int updatedMs;
  final String? syncedAt;
}
