import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mealprep/data/database.dart';
import 'package:mealprep/logic/defaults.dart';
import 'package:mealprep/logic/models.dart';
import 'package:mealprep/logic/scaling.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('nowa baza ma domyślne cele i posiłki', () async {
    final s = await db.loadSettings();
    expect(s.target.toJson(), defaultSettings.target.toJson());
    expect(s.trainingExtraKcal, 250);
    expect(s.trainingExtraFrom, Macro.c);
    expect(await db.loadMealSlots(), defaultMealSlots);
  });

  test('zapis i odczyt celów', () async {
    await db.saveSettings(
      const Settings(
        target: Macros(kcal: 3100, p: 190, f: 95, c: 375),
        trainingExtraKcal: 300,
        trainingExtraFrom: Macro.f,
      ),
    );
    final s = await db.loadSettings();
    expect(s.target.toJson(), {'kcal': 3100, 'p': 190, 'f': 95, 'c': 375});
    expect(s.trainingExtraKcal, 300);
    expect(s.trainingExtraFrom, Macro.f);
  });

  test('zapis posiłków zachowuje kolejność i zastępuje starą listę', () async {
    const slots = [
      MealSlot(name: 'Obiad', prep: true),
      MealSlot(name: 'Śniadanie', prep: false),
    ];
    await db.saveMealSlots(slots);
    expect(await db.loadMealSlots(), slots);
  });
}
