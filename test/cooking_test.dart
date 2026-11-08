import 'package:flutter_test/flutter_test.dart';
import 'package:mealprep/logic/cooking.dart';
import 'package:mealprep/logic/scaling.dart';
import 'package:mealprep/logic/session.dart';

import 'test_data.dart';

void main() {
  final catalog = loadCatalog();
  final expected = readJson('test/fixtures/proto_expected.json');
  final portions = planSession(
    Settings.fromJson(expected['settings'] as Map<String, dynamic>),
    Session.fromJson(expected['session'] as Map<String, dynamic>),
    catalog,
  );

  test('sumy na partię: chili z demo, zgodnie z listą zakupów', () {
    final totals = {
      for (final a in recipeTotals(portions, 'chili-con-carne'))
        a.productId: a.g,
    };
    // Mięso mielone występuje tylko w chili: 485 g jak na liście w prototypie.
    expect(totals['mielone-wolowe'], 485);
    // Kolejność z przepisu: pierwsze jest mięso.
    expect(
      recipeTotals(portions, 'chili-con-carne').first.productId,
      'mielone-wolowe',
    );
    expect(recipeTotals(portions, 'nie-ma'), isEmpty);
  });

  test('pudełka: 4 dni, udziały sumują się do 1, jak potShares', () {
    final boxes = boxesFor(portions, 'chili-con-carne');
    expect(boxes.map((b) => b.day), ['Pon', 'Wt', 'Śr', 'Czw']);
    expect(boxes.fold(0.0, (s, b) => s + b.share), closeTo(1, 1e-9));
    final shares = potShares(portions, 'obiad');
    for (final b in boxes) {
      expect(b.share, shares[b.day]);
    }
  });

  test('tekst kroku z wstawionymi gramaturami', () {
    final seg = fillStepText(
      'Ugotuj {ryz-bialy} ryżu na {olej} oleju, potem {x}.',
      {'ryz-bialy': 280, 'olej': 2.5},
    );
    expect(
      seg.map((s) => s.text).join(),
      'Ugotuj 280 g ryżu na 2,5 g oleju, potem {x}.',
    );
    expect(seg.where((s) => s.amount).map((s) => s.text), ['280 g', '2,5 g']);
    expect(fillStepText('Bez ilości.', const {}), [
      (text: 'Bez ilości.', amount: false),
    ]);
  });

  test('minutnik: start, pauza, wznowienie, koniec, reset', () {
    final t0 = DateTime(2026, 11, 9, 12);
    final t = StepTimer(const Duration(minutes: 15));
    expect(t.remaining(t0), const Duration(minutes: 15));
    expect(t.started(t0), isFalse);

    t.start(t0);
    expect(
      t.remaining(t0.add(const Duration(minutes: 5))),
      const Duration(minutes: 10),
    );

    t.pause(t0.add(const Duration(minutes: 5)));
    // Pauza: czas stoi.
    expect(
      t.remaining(t0.add(const Duration(hours: 1))),
      const Duration(minutes: 10),
    );
    expect(t.started(t0), isTrue);

    t.start(t0.add(const Duration(minutes: 20)));
    final end = t0.add(const Duration(minutes: 30));
    expect(t.finished(end), isTrue);
    expect(t.remaining(end.add(const Duration(minutes: 3))), Duration.zero);

    t.reset();
    expect(t.running, isFalse);
    expect(t.remaining(end), const Duration(minutes: 15));
  });

  test('format czasu', () {
    expect(formatDuration(const Duration(minutes: 15)), '15:00');
    expect(formatDuration(const Duration(seconds: 65)), '01:05');
    expect(
      formatDuration(const Duration(hours: 1, minutes: 2, seconds: 3)),
      '1:02:03',
    );
  });

  test('odmiana pudełek', () {
    expect([1, 2, 4, 5, 12, 22, 25].map(boxesWord), [
      'pudełko',
      'pudełka',
      'pudełka',
      'pudełek',
      'pudełek',
      'pudełka',
      'pudełek',
    ]);
  });
}
