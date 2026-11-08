/// Plan sesji w aplikacji: daty, posiłki, dni treningowe i wybrane dania.
///
/// To „opakowanie" na [Session] z session.dart: dokłada daty i listę posiłków,
/// a [toSession] zamienia je na wejście dla `planSession` (logika 1:1
/// z prototypu zostaje bez zmian).
library;

import 'models.dart';
import 'session.dart';

const _weekdays = ['Pon', 'Wt', 'Śr', 'Czw', 'Pt', 'Sob', 'Nd'];

/// Np. „Pon 10.11".
String dayLabel(DateTime d) =>
    '${_weekdays[d.weekday - 1]} ${d.day}.${d.month.toString().padLeft(2, '0')}';

/// Sama data (bez godziny).
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

String _isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}'
    '-${d.day.toString().padLeft(2, '0')}';

/// Typ posiłku z przepisów (`meal_types`) pasujący do nazwy posiłku,
/// np. „Drugie śniadanie" → `sniadanie`. `null`, gdy nic nie pasuje.
String? mealTypeForSlot(String slotName) {
  const plain = {'ś': 's', 'ą': 'a', 'ę': 'e', 'ó': 'o', 'ł': 'l', 'ż': 'z'};
  var n = slotName.toLowerCase();
  plain.forEach((k, v) => n = n.replaceAll(k, v));
  for (final t in const ['sniadanie', 'obiad', 'kolacja', 'przekaska']) {
    if (n.contains(t)) return t;
  }
  return null;
}

/// Jeden dzień sesji. Data wynika z pozycji na liście.
class PlanDay {
  const PlanDay({this.training = false, this.off = const {}});

  factory PlanDay.fromJson(Map<String, dynamic> j) => PlanDay(
    training: j['training'] as bool? ?? false,
    off: Set<String>.from(j['off'] as List? ?? const []),
  );

  final bool training;

  /// Nazwy posiłków wyłączonych tego dnia (np. bez śniadania).
  final Set<String> off;

  PlanDay copyWith({bool? training, Set<String>? off}) =>
      PlanDay(training: training ?? this.training, off: off ?? this.off);

  Map<String, dynamic> toJson() => {
    'training': training,
    'off': off.toList()..sort(),
  };
}

class SessionPlan {
  const SessionPlan({
    this.id,
    required this.firstDay,
    required this.slots,
    required this.days,
    this.recipes = const {},
  });

  /// Nowa sesja z posiłkami z ustawień; wszystkie posiłki włączone.
  factory SessionPlan.create({
    required DateTime firstDay,
    required int dayCount,
    required List<MealSlot> slots,
  }) => SessionPlan(
    firstDay: dateOnly(firstDay),
    slots: slots,
    days: List.filled(dayCount, const PlanDay()),
  );

  factory SessionPlan.fromJson(Map<String, dynamic> j, {int? id}) =>
      SessionPlan(
        id: id,
        firstDay: DateTime.parse(j['first_day'] as String),
        slots: [
          for (final s in j['slots'] as List)
            MealSlot(name: s['name'] as String, prep: s['prep'] as bool),
        ],
        days: [
          for (final d in j['days'] as List)
            PlanDay.fromJson(d as Map<String, dynamic>),
        ],
        recipes: Map<String, String>.from(j['recipes'] as Map? ?? const {}),
      );

  /// ID w bazie (`null`, dopóki nie zapisana).
  final int? id;
  final DateTime firstDay;

  /// Posiłki skopiowane z ustawień w chwili tworzenia sesji. Dzięki temu
  /// późniejsza zmiana ustawień nie psuje zapisanych planów.
  final List<MealSlot> slots;
  final List<PlanDay> days;

  /// Posiłek z prepu → ID przepisu.
  final Map<String, String> recipes;

  List<MealSlot> get prepSlots => [
    for (final s in slots)
      if (s.prep) s,
  ];

  DateTime dateOf(int dayIndex) =>
      DateTime(firstDay.year, firstDay.month, firstDay.day + dayIndex);

  DateTime get lastDay => dateOf(days.length - 1);

  String labelOf(int dayIndex) => dayLabel(dateOf(dayIndex));

  /// Ile posiłków je się danego dnia.
  int activeMeals(int dayIndex) =>
      slots.where((s) => !days[dayIndex].off.contains(s.name)).length;

  SessionPlan copyWith({
    int? id,
    DateTime? firstDay,
    List<PlanDay>? days,
    Map<String, String>? recipes,
  }) => SessionPlan(
    id: id ?? this.id,
    firstDay: firstDay ?? this.firstDay,
    slots: slots,
    days: days ?? this.days,
    recipes: recipes ?? this.recipes,
  );

  /// Zmienia liczbę dni; ustawienia istniejących dni zostają.
  SessionPlan withDayCount(int n) => copyWith(
    days: [
      for (var i = 0; i < n; i++) i < days.length ? days[i] : const PlanDay(),
    ],
  );

  SessionPlan withDay(int i, PlanDay d) => copyWith(days: [...days]..[i] = d);

  SessionPlan withRecipe(String slot, String? recipeId) {
    final r = {...recipes};
    if (recipeId == null) {
      r.remove(slot);
    } else {
      r[slot] = recipeId;
    }
    return copyWith(recipes: r);
  }

  /// Wejście dla `planSession`. Dzień nazywa się jak etykieta daty.
  Session toSession() => Session(
    days: [
      for (var i = 0; i < days.length; i++)
        SessionDay(
          name: labelOf(i),
          training: days[i].training,
          meals: {for (final s in slots) s.name: !days[i].off.contains(s.name)},
        ),
    ],
    prep: {
      for (final s in prepSlots)
        if (recipes[s.name] != null) s.name: recipes[s.name]!,
    },
  );

  Map<String, dynamic> toJson() => {
    'first_day': _isoDate(firstDay),
    'slots': [
      for (final s in slots) {'name': s.name, 'prep': s.prep},
    ],
    'days': [for (final d in days) d.toJson()],
    'recipes': recipes,
  };
}

/// Sesja, którą domyślnie pokazujemy w Zakupach: najwcześniejsza z tych,
/// które jeszcze się nie skończyły (trwa albo dopiero będzie). Gdy takich
/// nie ma, najnowsza. `null`, gdy nie ma żadnej sesji.
SessionPlan? defaultShoppingSession(
  List<SessionPlan> sessions,
  DateTime today,
) {
  final t = dateOnly(today);
  SessionPlan? best;
  for (final s in sessions) {
    if (s.lastDay.isBefore(t)) continue;
    if (best == null || s.firstDay.isBefore(best.firstDay)) best = s;
  }
  if (best != null) return best;
  SessionPlan? newest;
  for (final s in sessions) {
    if (newest == null || s.firstDay.isAfter(newest.firstDay)) newest = s;
  }
  return newest;
}
