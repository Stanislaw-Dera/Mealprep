/// Walidacja przepisu: port `validate_recipe` z tools/mealprep_proto.py.
///
/// Działa na surowym JSON-ie (mapie), a nie na klasie [Recipe], bo ma wyłapać
/// błędy *zanim* spróbujemy zbudować model. Przyda się na ekranie „Importuj".
library;

import 'models.dart';

const mealTypes = {'sniadanie', 'obiad', 'kolacja', 'przekaska'};

/// Prefiks ostrzeżeń, które nie blokują zapisu przepisu.
const warningPrefix = 'uwaga';

bool isWarning(String message) => message.startsWith(warningPrefix);

/// Zwraca listę błędów i ostrzeżeń. Pusta lista = przepis OK.
List<String> validateRecipe(
  Map<String, dynamic> r,
  Map<String, Product> products,
) {
  final e = <String>[];
  for (final key in const [
    'format',
    'id',
    'name',
    'meal_types',
    'prep',
    'time_min',
    'ingredients',
    'steps',
  ]) {
    if (!r.containsKey(key)) e.add("brak pola '$key'");
  }
  if (e.isNotEmpty) return e;

  if (r['format'] != 'mealprep/1') e.add("format musi być 'mealprep/1'");

  final unknown = (r['meal_types'] as List).toSet().difference(mealTypes);
  if (unknown.isNotEmpty) {
    // Format jak zbiór w Pythonie: {'deser'}
    final items = unknown.map((t) => "'$t'").toList()..sort();
    e.add('nieznane meal_types: {${items.join(', ')}}');
  }
  if (r['prep'] == true && !r.containsKey('fridge_days')) {
    e.add("danie do prepu potrzebuje 'fridge_days'");
  }

  final scalable = <Product>[];
  for (final ing in (r['ingredients'] as List).cast<Map<String, dynamic>>()) {
    final pid = ing['product'];
    final product = products[pid];
    if (product == null) {
      e.add("nieznany produkt '$pid'");
      continue;
    }
    final hasMin = ing.containsKey('min');
    final hasMax = ing.containsKey('max');
    if (hasMin != hasMax) e.add("$pid: podaj oba 'min' i 'max'");
    // Prototyp przy samym 'min' bez 'max' rzuca wyjątkiem; tu tylko pomijamy zakres.
    if (hasMin && hasMax) {
      final g = ing['g'] as num, lo = ing['min'] as num, hi = ing['max'] as num;
      if (!(lo <= g && g <= hi)) {
        e.add('$pid: g=$g poza zakresem $lo-$hi');
      }
    }
    if (hasMin) scalable.add(product);
  }

  // Czy jest czym sterować białkiem, tłuszczem i węglowodanami.
  if (scalable.isNotEmpty) {
    // Produkt „steruje" makroskładnikiem, jeśli daje ≥30% jego energii.
    final have = <Macro>{};
    for (final p in scalable) {
      final m = p.per100g;
      final en = {Macro.p: 4 * m.p, Macro.f: 9 * m.f, Macro.c: 4 * m.c};
      var tot = en.values.fold(0.0, (a, b) => a + b);
      if (tot == 0) tot = 1;
      have.addAll(
        en.entries.where((x) => x.value / tot >= 0.3).map((x) => x.key),
      );
    }
    const missing = {
      Macro.p: 'białka',
      Macro.f: 'tłuszczu',
      Macro.c: 'węglowodanów',
    };
    for (final m in const [Macro.p, Macro.f, Macro.c]) {
      if (!have.contains(m)) {
        e.add('$warningPrefix: brak skalowalnego źródła ${missing[m]}');
      }
    }
  } else {
    e.add('$warningPrefix: brak składników skalowalnych - porcja będzie stała');
  }

  final steps = (r['steps'] as List).cast<Map<String, dynamic>>();
  for (var i = 1; i <= steps.length; i++) {
    final s = steps[i - 1];
    if (!s.containsKey('text') || !s.containsKey('min')) {
      e.add("krok $i: wymagane 'text' i 'min'");
    }
    for (final a in (s['after'] as List? ?? const [])) {
      if (!(1 <= a && a < i)) {
        e.add(
          "krok $i: 'after' może wskazywać tylko wcześniejsze kroki (jest $a)",
        );
      }
    }
  }
  return e;
}
