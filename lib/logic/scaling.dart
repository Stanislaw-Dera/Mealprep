/// Skalowanie porcji pod cel makro: port `macros_of`, `scale_recipe`,
/// `day_target` i `meal_target` z tools/mealprep_proto.py.
///
/// Uwaga: kolejność działań na liczbach jest celowo taka sama jak w Pythonie,
/// żeby wyniki zgadzały się co do bitu (test/logic_parity_test.dart).
library;

import 'dart:math' as math;

import 'models.dart';

/// Domyślny krok zaokrąglenia gramatur.
const roundG = 5.0;

/// Suma makro dla listy (produkt, gramy).
Macros macrosOf(Iterable<Amount> items, Map<String, Product> products) {
  final tot = [0.0, 0.0, 0.0, 0.0];
  for (final (:productId, :g) in items) {
    final p = products[productId]!.per100g;
    for (final m in Macro.values) {
      tot[m.index] += p[m] * g / 100;
    }
  }
  return Macros(kcal: tot[0], p: tot[1], f: tot[2], c: tot[3]);
}

/// Zaokrąglenie jak `round()` w Pythonie: połówki do parzystej (2.5 → 2).
/// Dartowe `.round()` zaokrągla połówki w górę, więc dałoby inne wyniki.
double pyRound(double x) {
  final f = x.floorToDouble();
  final diff = x - f;
  if (diff > 0.5) return f + 1;
  if (diff < 0.5) return f;
  return f % 2 == 0 ? f : f + 1;
}

/// Dobiera gramatury składników skalowalnych pod [target] posiłku.
///
/// Minimalizuje  Σ w_m ((makro_m − cel_m)/cel_m)²  +  reg · Σ ((x_i − g_i)/s_i)²
/// przy  min_i ≤ x_i ≤ max_i. Regularyzacja trzyma proporcje blisko przepisu,
/// gdy kilka rozwiązań jest równie dobrych.
///
/// Metoda: „projected coordinate descent". Po kolei dla każdej zmiennej
/// liczymy jej najlepszą wartość przy pozostałych ustalonych i przycinamy
/// do [min, max]. 300 przebiegów wystarcza dla 2–5 zmiennych.
///
/// Zwraca gramatury wszystkich składników w kolejności z przepisu.
List<Amount> scaleRecipe(
  Recipe r,
  Map<String, Product> products,
  Macros target, {
  double reg = 0.02,
}) {
  final fixed = <Amount>[
    for (final i in r.ingredients)
      if (!i.scalable) (productId: i.productId, g: i.g),
  ];
  final vars = [
    for (final i in r.ingredients)
      if (i.scalable) i,
  ];
  final n = vars.length;
  final base = macrosOf(fixed, products);

  // Układ równań w postaci wierszy (a, b): chcemy, żeby  a·x ≈ b.
  // Dla każdego makro m:  sqrt(w)/t · (base_m + Σ a_mi x_i − t_m)
  final rows = <(List<double>, double)>[];
  for (final m in Macro.values) {
    final t = math.max(target[m], 1e-6);
    final k = math.sqrt(m.weight) / t;
    rows.add((
      [for (final i in vars) k * products[i.productId]!.per100g[m] / 100],
      k * (t - base[m]),
    ));
  }
  // Regularyzacja: każda zmienna „chce" zostać przy gramaturze z przepisu.
  for (var j = 0; j < n; j++) {
    final i = vars[j];
    final s = [i.g, i.max! / 2, 1.0].reduce(math.max);
    final coef = List<double>.filled(n, 0.0);
    coef[j] = math.sqrt(reg) / s;
    rows.add((coef, math.sqrt(reg) / s * i.g));
  }

  final x = [for (final i in vars) i.g];
  final lo = [for (final i in vars) i.min!];
  final hi = [for (final i in vars) i.max!];
  for (var iter = 0; iter < 300; iter++) {
    for (var j = 0; j < n; j++) {
      var num = 0.0, den = 0.0;
      for (final (a, b) in rows) {
        var sum = 0.0;
        for (var k = 0; k < n; k++) {
          if (k != j) sum += a[k] * x[k];
        }
        final rest = b - sum;
        num += a[j] * rest;
        den += a[j] * a[j];
      }
      if (den > 0) x[j] = math.min(hi[j], math.max(lo[j], num / den));
    }
  }

  final out = <Amount>[...fixed];
  for (var j = 0; j < n; j++) {
    final i = vars[j];
    final step = i.step ?? roundG;
    var g = pyRound(x[j] / step) * step;
    g = math.min(i.max!, math.max(i.min!, g));
    out.add((productId: i.productId, g: g));
  }

  // Zachowaj kolejność z przepisu (przy powtórzonym produkcie liczy się
  // ostatnie wystąpienie, jak słownik w Pythonie). Sortowanie stabilne.
  final order = <String, int>{
    for (var k = 0; k < r.ingredients.length; k++)
      r.ingredients[k].productId: k,
  };
  final indexed = [for (var k = 0; k < out.length; k++) (k, out[k])];
  indexed.sort((a, b) {
    final c = order[a.$2.productId]!.compareTo(order[b.$2.productId]!);
    return c != 0 ? c : a.$1.compareTo(b.$1);
  });
  return [for (final e in indexed) e.$2];
}

/// Ustawienia celów (ekran „Cele").
class Settings {
  const Settings({
    required this.target,
    this.trainingExtraKcal = 250,
    this.trainingExtraFrom = Macro.c,
  });

  factory Settings.fromJson(Map<String, dynamic> j) => Settings(
    target: Macros.fromJson(j['target'] as Map<String, dynamic>),
    trainingExtraKcal: (j['training_extra_kcal'] as num).toDouble(),
    trainingExtraFrom: Macro.fromKey(j['training_extra_from'] as String),
  );

  /// Cel na zwykły dzień.
  final Macros target;

  /// Dodatkowe kcal w dzień treningowy.
  final double trainingExtraKcal;

  /// Z jakiego makroskładnika pochodzą dodatkowe kcal.
  final Macro trainingExtraFrom;
}

/// Cel dnia, z dodatkiem w dzień treningowy.
Macros dayTarget(Settings settings, {required bool training}) {
  var t = settings.target;
  if (training) {
    final extra = settings.trainingExtraKcal;
    t = t.withValue(Macro.kcal, t.kcal + extra);
    final m = settings.trainingExtraFrom;
    t = t.withValue(m, t[m] + extra / (m == Macro.f ? 9 : 4));
  }
  return t;
}

/// Cel jednego posiłku: cel dnia dzielony równo na posiłki.
Macros mealTarget(Macros dayT, int nMeals) => dayT / nMeals.toDouble();
