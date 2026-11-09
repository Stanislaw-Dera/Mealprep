import 'package:flutter_test/flutter_test.dart';
import 'package:mealprep/ui/cooking_timers.dart';

import 'test_data.dart';

void main() {
  final catalog = loadCatalog();
  final chili = catalog.recipes['chili-con-carne']!; // krok 1: 15 min
  final curry = catalog.recipes['kurczak-curry-ryz']!;

  test('minutniki w dwóch daniach naraz, powiadomienie raz', () {
    var now = DateTime(2026, 11, 9, 18);
    final finished = <String>[];
    final timers = CookingTimers(
      clock: () => now,
      onFinished: (t) => finished.add(t.key),
    );
    addTearDown(timers.dispose);

    final rice = timers.of(chili, 0);
    expect(identical(timers.of(chili, 0), rice), isTrue); // ten sam minutnik
    final curryStep = timers.of(curry, 0);

    timers.startPause(rice);
    now = now.add(const Duration(minutes: 5));
    timers.startPause(curryStep);
    expect(timers.runningCount, 2);
    expect(timers.active, [rice, curryStep]);

    // Po 15 min od startu ryżu: ryż gotowy, curry dalej chodzi.
    now = DateTime(2026, 11, 9, 18, 15);
    timers.tick();
    timers.tick(); // drugi raz bez drugiego powiadomienia
    expect(finished, ['chili-con-carne#0']);
    expect(timers.runningCount, 1);
    expect(timers.active, contains(rice)); // skończony, ale jeszcze widoczny

    // Zamknięcie skończonego minutnika.
    timers.reset(rice);
    expect(timers.active, [curryStep]);
    expect(rice.announced, isFalse);
  });

  test('pauza zatrzymuje odliczanie', () {
    var now = DateTime(2026, 11, 9, 18);
    final timers = CookingTimers(clock: () => now);
    addTearDown(timers.dispose);
    final t = timers.of(chili, 0);

    timers.startPause(t);
    now = now.add(const Duration(minutes: 3));
    timers.startPause(t); // pauza
    now = now.add(const Duration(hours: 1));
    expect(t.timer.remaining(now), const Duration(minutes: 12));
    expect(timers.runningCount, 0);
    expect(timers.active, [t]); // zapauzowany wciąż „w użyciu"
  });
}
