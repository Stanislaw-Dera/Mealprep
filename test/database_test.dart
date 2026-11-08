import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mealprep/data/database.dart';
import 'package:mealprep/logic/defaults.dart';
import 'package:mealprep/logic/models.dart';
import 'package:mealprep/logic/scaling.dart';
import 'package:mealprep/logic/session_plan.dart';

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

  test('zapis, odczyt i usuwanie sesji', () async {
    final plan = SessionPlan.create(
      firstDay: DateTime(2026, 11, 9),
      dayCount: 3,
      slots: defaultMealSlots,
    ).withRecipe('Obiad', 'chili-con-carne');

    final saved = await db.saveSession(plan);
    expect(saved.id, isNotNull);
    await db.saveSession(saved.withDay(0, const PlanDay(training: true)));
    await db.saveSession(
      SessionPlan.create(
        firstDay: DateTime(2026, 11, 12),
        dayCount: 4,
        slots: defaultMealSlots,
      ),
    );

    final all = await db.loadSessions();
    expect(all.length, 2);
    expect(all.first.firstDay, DateTime(2026, 11, 12)); // najnowsza na górze
    expect(all.last.days.first.training, isTrue);
    expect(all.last.recipes, {'Obiad': 'chili-con-carne'});

    await db.deleteSession(saved.id!);
    expect((await db.loadSessions()).length, 1);
  });

  test('migracja z wersji 1 zachowuje cele i dodaje nowe tabele', () async {
    final dir = Directory.systemTemp.createTempSync('mealprep_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/v1.sqlite');

    // Schemat dokładnie jak w bazie z wersji 1 aplikacji.
    final old = AppDatabase(
      NativeDatabase(
        file,
        setup: (raw) {
          if (raw.userVersion != 0) return;
          raw.execute('''
            CREATE TABLE "goals" ("id" INTEGER NOT NULL DEFAULT 1, "kcal" REAL NOT NULL,
              "protein" REAL NOT NULL, "fat" REAL NOT NULL, "carbs" REAL NOT NULL,
              "training_extra_kcal" REAL NOT NULL, "training_extra_from" TEXT NOT NULL,
              PRIMARY KEY ("id"));
            CREATE TABLE "meal_slots" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              "name" TEXT NOT NULL, "position" INTEGER NOT NULL,
              "prep" INTEGER NOT NULL CHECK ("prep" IN (0, 1)));
            INSERT INTO goals VALUES (1, 3100, 190, 95, 375, 300, 'c');
            INSERT INTO meal_slots (name, position, prep) VALUES ('Obiad', 0, 1);
          ''');
          raw.userVersion = 1;
        },
      ),
    );
    addTearDown(old.close);

    expect((await old.loadSettings()).target.kcal, 3100);
    expect(await old.loadMealSlots(), [
      const MealSlot(name: 'Obiad', prep: true),
    ]);
    expect(await old.loadSessions(), isEmpty);
    final s = await old.saveSession(
      SessionPlan.create(
        firstDay: DateTime(2026, 11, 9),
        dayCount: 3,
        slots: const [MealSlot(name: 'Obiad', prep: true)],
      ),
    );
    expect(s.id, 1);
    await old.setChecked(1, 'ryz-bialy', true);
    expect(await old.watchChecks(1).first, {'ryz-bialy'});
  });

  test('odhaczanie zakupów i czyszczenie przy usunięciu sesji', () async {
    final a = await db.saveSession(
      SessionPlan.create(
        firstDay: DateTime(2026, 11, 9),
        dayCount: 3,
        slots: defaultMealSlots,
      ),
    );
    final b = await db.saveSession(
      SessionPlan.create(
        firstDay: DateTime(2026, 11, 12),
        dayCount: 4,
        slots: defaultMealSlots,
      ),
    );
    await db.setChecked(a.id!, 'ryz-bialy', true);
    await db.setChecked(a.id!, 'cebula', true);
    await db.setChecked(a.id!, 'cebula', true); // drugi raz: bez błędu
    await db.setChecked(b.id!, 'ryz-bialy', true);
    expect(await db.watchChecks(a.id!).first, {'ryz-bialy', 'cebula'});

    await db.setChecked(a.id!, 'cebula', false);
    expect(await db.watchChecks(a.id!).first, {'ryz-bialy'});

    await db.clearChecks(b.id!);
    expect(await db.watchChecks(b.id!).first, isEmpty);

    await db.deleteSession(a.id!);
    expect(await db.select(db.shoppingChecks).get(), isEmpty);
  });
}
