// Zgodność logiki w Darcie z prototypem w Pythonie (tools/mealprep_proto.py).
//
// Oczekiwane wyniki są w test/fixtures/proto_expected.json. Generuje je
// `python3 tools/export_test_fixture.py`. Po zmianie danych albo prototypu
// wygeneruj plik od nowa i uruchom `flutter test`.

import 'package:flutter_test/flutter_test.dart';
import 'package:mealprep/logic/models.dart';
import 'package:mealprep/logic/scaling.dart';
import 'package:mealprep/logic/schedule.dart';
import 'package:mealprep/logic/session.dart';
import 'package:mealprep/logic/shopping.dart';
import 'package:mealprep/logic/validate.dart';

import 'test_data.dart';

/// Lista (produkt, gramy) w formacie fixture: [["ryz-bialy", 60], ...]
List<List<Object>> _items(List<Amount> items) => [
  for (final (:productId, :g) in items) [productId, g],
];

void main() {
  final expected = readJson('test/fixtures/proto_expected.json');

  // Ta sama baza co w aplikacji, wczytana z dysku (pliki posortowane po nazwie).
  final recipesJson = readRecipesJson();
  final catalog = loadCatalog();

  final settings = Settings.fromJson(
    expected['settings'] as Map<String, dynamic>,
  );
  final session = Session.fromJson(expected['session'] as Map<String, dynamic>);

  test('wczytanie bazy', () {
    expect(catalog.recipes.length, 27);
    expect(catalog.products.length, 130);
  });

  group('walidacja', () {
    test('wbudowane przepisy', () {
      final exp = expected['validation'] as Map<String, dynamic>;
      for (final rj in recipesJson) {
        expect(
          validateRecipe(rj, catalog.products),
          exp[rj['id']],
          reason: rj['id'] as String,
        );
      }
    });

    final bad = expected['bad_validation'] as Map<String, dynamic>;
    for (final MapEntry(key: name, value: v) in bad.entries) {
      test('zepsuty przepis: $name', () {
        final c = v as Map<String, dynamic>;
        expect(
          validateRecipe(c['recipe'] as Map<String, dynamic>, catalog.products),
          c['errors'],
        );
      });
    }
  });

  test('solver: każdy przepis przy 3, 4 i 5 posiłkach dziennie', () {
    final exp = expected['scaling'] as Map<String, dynamic>;
    for (final MapEntry(key: rid, value: byN) in exp.entries) {
      for (final MapEntry(key: n, value: items) in (byN as Map).entries) {
        final t = mealTarget(settings.target, int.parse(n as String));
        expect(
          _items(scaleRecipe(catalog.recipes[rid]!, catalog.products, t)),
          items,
          reason: '$rid, $n posiłków',
        );
      }
    }
  });

  final portions = planSession(settings, session, catalog);

  test('sesja demo: porcje, makro i cele', () {
    final exp = expected['portions'] as List;
    expect(portions.length, exp.length);
    for (var k = 0; k < exp.length; k++) {
      final e = exp[k] as Map<String, dynamic>;
      final p = portions[k];
      final why = '${p.day} ${p.slot}';
      expect(p.day, e['day'], reason: why);
      expect(p.slot, e['slot'], reason: why);
      expect(p.recipeId, e['recipe'], reason: why);
      expect(_items(p.items), e['items'], reason: why);
      expect(p.macros.toJson(), e['macros'], reason: why);
      expect(p.target.toJson(), e['target'], reason: why);
    }
  });

  test('podział garnka sumuje się do 100%', () {
    for (final slot in session.prep.keys) {
      final shares = potShares(portions, slot);
      expect(shares.values.fold(0.0, (a, b) => a + b), closeTo(1, 1e-9));
    }
  });

  test('lista zakupów', () {
    final list = shoppingList(portions, catalog);
    final exp = expected['shopping'] as Map<String, dynamic>;
    expect([
      for (final g in list.groups)
        {
          'cat': g.categoryId,
          'items': [
            for (final i in g.items) [i.name, i.needG, i.label],
          ],
        },
    ], exp['groups']);
    expect([
      for (final i in list.check) [i.name, i.needG],
    ], exp['check']);
  });

  test('wspólny plan sesji', () {
    final s = scheduleSession(session.prep.values.toList(), catalog.recipes);
    final exp = expected['schedule'] as Map<String, dynamic>;
    expect([
      for (final t in s.plan) [t.recipeId, t.stepNo, t.start, t.end],
    ], exp['plan']);
    expect(s.total, exp['total']);
    expect(s.sequential, exp['seq']);
  });

  group('drobiazgi', () {
    test('pyRound zaokrągla połówki do parzystej, jak Python', () {
      expect([0.5, 1.5, 2.5, 3.5, 2.4, 2.6].map(pyRound), [0, 2, 2, 4, 2, 3]);
    });

    test('bestPacks: najmniejsza nadwyżka, potem najmniej opakowań', () {
      expect(bestPacks(380, [400]).counts, [1]);
      expect(bestPacks(500, [250, 500]).counts, [0, 1]);
      expect(bestPacks(5000, [400]).total, 5200); // ponad 7 opakowań
    });
  });
}
