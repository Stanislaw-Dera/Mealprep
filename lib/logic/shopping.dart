/// Lista zakupów: port `best_packs` i `shopping_list` z tools/mealprep_proto.py.
library;

import 'models.dart';
import 'session.dart';

/// Wybór opakowań: najmniejsza nadwyżka, potem najmniej opakowań.
/// Sprawdza każdą kombinację 0–7 sztuk każdego rozmiaru, w tej samej
/// kolejności co `itertools.product` (przy remisie wygrywa pierwsza).
///
/// Zwraca liczbę sztuk każdego rozmiaru i łączną wagę.
({List<int> counts, int total}) bestPacks(double need, List<int> packs) {
  ({double surplus, int count, List<int> counts, int total})? best;
  final counts = List<int>.filled(packs.length, 0);

  void visit(int pos) {
    if (pos == packs.length) {
      var tot = 0, cnt = 0;
      for (var k = 0; k < packs.length; k++) {
        tot += counts[k] * packs[k];
        cnt += counts[k];
      }
      if (tot < need || cnt == 0) return;
      final surplus = tot - need;
      if (best == null ||
          surplus < best!.surplus ||
          (surplus == best!.surplus && cnt < best!.count)) {
        best = (surplus: surplus, count: cnt, counts: [...counts], total: tot);
      }
      return;
    }
    for (var c = 0; c < 8; c++) {
      counts[pos] = c;
      visit(pos + 1);
    }
  }

  visit(0);
  if (best == null) {
    // Prototyp tu się wywraca (potrzeba > 7 największych opakowań).
    // Bierzemy wtedy tyle największych opakowań, ile trzeba.
    var big = 0;
    for (var k = 1; k < packs.length; k++) {
      if (packs[k] > packs[big]) big = k;
    }
    final n = (need / packs[big]).ceil();
    final c = List<int>.filled(packs.length, 0)..[big] = n;
    return (counts: c, total: n * packs[big]);
  }
  return (counts: best!.counts, total: best!.total);
}

/// Pozycja do kupienia.
class ShoppingItem {
  const ShoppingItem({
    required this.productId,
    required this.name,
    required this.needG,
    required this.label,
  });

  final String productId;
  final String name;

  /// Ile gramów potrzeba według przepisów.
  final double needG;

  /// Co kupić, np. „2× 400 g", „3 szt (~450 g)", „150 g (na wagę)".
  final String label;
}

/// Pozycje jednego działu sklepu.
class ShoppingGroup {
  const ShoppingGroup({required this.categoryId, required this.items});
  final String categoryId;
  final List<ShoppingItem> items;
}

class ShoppingList {
  const ShoppingList({required this.groups, required this.check});

  /// Działy w kolejności sklepu.
  final List<ShoppingGroup> groups;

  /// „Sprawdź, czy masz": produkty `staple` (bez etykiety opakowania).
  final List<ShoppingItem> check;
}

/// Liczba bez „.0" na końcu, gdy jest całkowita (jak int w Pythonie).
String _g(num v) => v == v.roundToDouble() ? v.toInt().toString() : '$v';

ShoppingList shoppingList(List<Portion> portions, Catalog catalog) {
  // Sumy gramatur w kolejności pierwszego wystąpienia.
  final need = <String, double>{};
  for (final por in portions) {
    for (final (:productId, :g) in por.items) {
      need[productId] = (need[productId] ?? 0) + g;
    }
  }

  final buy = <String, List<ShoppingItem>>{};
  final check = <ShoppingItem>[];
  for (final MapEntry(key: pid, value: g) in need.entries) {
    if (g <= 0) continue;
    final p = catalog.products[pid]!;
    if (p.staple) {
      check.add(
        ShoppingItem(productId: pid, name: p.name, needG: g, label: ''),
      );
      continue;
    }
    final String label;
    if (p.packs.isNotEmpty) {
      final (:counts, total: _) = bestPacks(g, p.packs);
      label = [
        for (var k = 0; k < counts.length; k++)
          if (counts[k] > 0) '${counts[k]}× ${p.packs[k]} g',
      ].join(' + ');
    } else if (p.pieceG != null) {
      // Tolerancja: 1,1 szt → 1 szt.
      var n = (g / p.pieceG! - 0.15).ceil();
      if (n < 1) n = 1;
      label = '$n szt (~${n * p.pieceG!} g)';
    } else {
      label = '${_g((g / 50).ceil() * 50)} g (na wagę)';
    }
    buy
        .putIfAbsent(p.category, () => [])
        .add(
          ShoppingItem(productId: pid, name: p.name, needG: g, label: label),
        );
  }

  return ShoppingList(
    groups: [
      for (final c in catalog.categories)
        if (buy.containsKey(c.id))
          ShoppingGroup(categoryId: c.id, items: buy[c.id]!),
    ],
    check: check,
  );
}
