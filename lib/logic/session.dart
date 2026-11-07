/// Planowanie sesji gotowania: port `plan_session` z tools/mealprep_proto.py
/// oraz podział garnka na pudełka (z `cmd_demo`).
library;

import 'models.dart';
import 'scaling.dart';

/// Jeden dzień objęty sesją.
class SessionDay {
  const SessionDay({
    required this.name,
    required this.training,
    required this.meals,
  });

  factory SessionDay.fromJson(Map<String, dynamic> j) => SessionDay(
    name: j['name'] as String,
    training: j['training'] as bool,
    meals: Map<String, bool>.from(j['meals'] as Map),
  );

  final String name;
  final bool training;

  /// Posiłki dnia w kolejności: nazwa → czy jest tego dnia (np. bez śniadania).
  final Map<String, bool> meals;
}

/// Sesja: dni + jedno danie na każdy posiłek z prepu.
class Session {
  const Session({required this.days, required this.prep});

  factory Session.fromJson(Map<String, dynamic> j) => Session(
    days: [
      for (final d in j['days'] as List)
        SessionDay.fromJson(d as Map<String, dynamic>),
    ],
    prep: Map<String, String>.from(j['prep'] as Map),
  );

  final List<SessionDay> days;

  /// Posiłek → ID przepisu. Posiłków, których tu nie ma, nie gotujemy w sesji.
  final Map<String, String> prep;
}

/// Jedno pudełko: konkretny dzień i posiłek.
class Portion {
  const Portion({
    required this.day,
    required this.slot,
    required this.recipeId,
    required this.items,
    required this.macros,
    required this.target,
  });

  final String day;
  final String slot;
  final String recipeId;
  final List<Amount> items;
  final Macros macros;
  final Macros target;

  double get totalG => items.fold(0.0, (s, i) => s + i.g);
}

/// Porcje na każdy dzień i posiłek z prepu.
///
/// Cel dnia dzielimy przez liczbę *wszystkich* aktywnych posiłków dnia,
/// także tych „na bieżąco", ale skalujemy tylko posiłki z prepu.
List<Portion> planSession(Settings settings, Session session, Catalog catalog) {
  final portions = <Portion>[];
  for (final d in session.days) {
    final active = [
      for (final e in d.meals.entries)
        if (e.value) e.key,
    ];
    final mt = mealTarget(
      dayTarget(settings, training: d.training),
      active.length,
    );
    for (final slot in active) {
      final rid = session.prep[slot];
      if (rid == null) continue;
      final items = scaleRecipe(catalog.recipes[rid]!, catalog.products, mt);
      portions.add(
        Portion(
          day: d.name,
          slot: slot,
          recipeId: rid,
          items: items,
          macros: macrosOf(items, catalog.products),
          target: mt,
        ),
      );
    }
  }
  return portions;
}

/// Jaką część garnka danego posiłku nałożyć do każdego pudełka (0–1).
/// Klucz: nazwa dnia. Porcje różnią się między dniami (np. dzień treningowy).
Map<String, double> potShares(List<Portion> portions, String slot) {
  final ps = portions.where((p) => p.slot == slot).toList();
  final tot = ps.fold(0.0, (s, p) => s + p.totalG);
  return {for (final p in ps) p.day: p.totalG / tot};
}
