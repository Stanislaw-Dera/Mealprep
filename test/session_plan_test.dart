import 'package:flutter_test/flutter_test.dart';
import 'package:mealprep/logic/models.dart';
import 'package:mealprep/logic/scaling.dart';
import 'package:mealprep/logic/session.dart';
import 'package:mealprep/logic/session_plan.dart';

import 'test_data.dart';

void main() {
  final catalog = loadCatalog();
  final expected = readJson('test/fixtures/proto_expected.json');

  const slots = [
    MealSlot(name: 'śniadanie', prep: false),
    MealSlot(name: 'obiad', prep: true),
    MealSlot(name: 'kolacja', prep: true),
    MealSlot(name: 'przekąska', prep: false),
  ];

  /// Sesja z `mealprep_proto.py demo`: Pon–Czw, trening Wt i Czw, w Śr bez śniadania.
  SessionPlan demoPlan() =>
      SessionPlan.create(
            firstDay: DateTime(2026, 11, 9), // poniedziałek
            dayCount: 4,
            slots: slots,
          )
          .withDay(1, const PlanDay(training: true))
          .withDay(2, const PlanDay(off: {'śniadanie'}))
          .withDay(3, const PlanDay(training: true))
          .withRecipe('obiad', 'chili-con-carne')
          .withRecipe('kolacja', 'kurczak-curry-ryz');

  test('SessionPlan daje te same porcje co demo w prototypie', () {
    final settings = Settings.fromJson(
      expected['settings'] as Map<String, dynamic>,
    );
    final portions = planSession(settings, demoPlan().toSession(), catalog);
    final exp = expected['portions'] as List;
    expect(portions.length, exp.length);
    for (var k = 0; k < exp.length; k++) {
      final e = exp[k] as Map<String, dynamic>;
      expect(portions[k].slot, e['slot']);
      expect([
        for (final a in portions[k].items) [a.productId, a.g],
      ], e['items']);
      expect(portions[k].macros.toJson(), e['macros']);
    }
    expect(portions.map((p) => p.day).toSet(), {
      'Pon 9.11',
      'Wt 10.11',
      'Śr 11.11',
      'Czw 12.11',
    });
  });

  test('zapis do JSON i z powrotem', () {
    final p = demoPlan();
    final back = SessionPlan.fromJson(p.toJson(), id: 7);
    expect(back.id, 7);
    expect(back.toJson(), p.toJson());
    expect(p.toJson()['first_day'], '2026-11-09');
  });

  test('zmiana liczby dni zachowuje ustawienia istniejących dni', () {
    final p = demoPlan().withDayCount(2).withDayCount(3);
    expect(p.days[1].training, isTrue);
    expect(p.days[2].off, isEmpty); // nowy dzień, domyślny
    expect(p.lastDay, DateTime(2026, 11, 11));
  });

  test('daty przechodzą przez koniec miesiąca i zmianę czasu', () {
    final p = SessionPlan.create(
      firstDay: DateTime(2026, 10, 24),
      dayCount: 4,
      slots: slots,
    );
    expect(p.lastDay, DateTime(2026, 10, 27));
    expect(p.labelOf(1), 'Nd 25.10');
  });

  test('typ posiłku z nazwy', () {
    expect(mealTypeForSlot('Drugie śniadanie'), 'sniadanie');
    expect(mealTypeForSlot('Przekąska'), 'przekaska');
    expect(mealTypeForSlot('Kolacja'), 'kolacja');
    expect(mealTypeForSlot('Po treningu'), isNull);
  });
}
