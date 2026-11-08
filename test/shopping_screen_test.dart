import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mealprep/data/database.dart';
import 'package:mealprep/logic/models.dart';
import 'package:mealprep/logic/scaling.dart';
import 'package:mealprep/logic/session_plan.dart';
import 'package:mealprep/main.dart';

import 'app_test_utils.dart';
import 'test_data.dart';

void main() {
  late AppDatabase db;
  final catalog = loadCatalog();
  final expected = readJson('test/fixtures/proto_expected.json');

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  testAppWidgets('lista dla sesji demo jak w prototypie, z odhaczaniem', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // Cele i sesja jak w `mealprep_proto.py demo`.
    await tester.runAsync(() async {
      await db.saveSettings(
        Settings.fromJson(expected['settings'] as Map<String, dynamic>),
      );
      final today = dateOnly(DateTime.now());
      await db.saveSession(
        SessionPlan.create(
              firstDay: today,
              dayCount: 4,
              slots: const [
                MealSlot(name: 'śniadanie', prep: false),
                MealSlot(name: 'obiad', prep: true),
                MealSlot(name: 'kolacja', prep: true),
                MealSlot(name: 'przekąska', prep: false),
              ],
            )
            .withDay(1, const PlanDay(training: true))
            .withDay(2, const PlanDay(off: {'śniadanie'}))
            .withDay(3, const PlanDay(training: true))
            .withRecipe('obiad', 'chili-con-carne')
            .withRecipe('kolacja', 'kurczak-curry-ryz'),
      );
    });

    await tester.pumpWidget(MealprepApp(db: db, catalog: catalog));
    await tester.tap(find.text('Zakupy').first);
    await settle(tester);

    // Każda pozycja z prototypu: nazwa i etykieta opakowania.
    final shopping = expected['shopping'] as Map<String, dynamic>;
    var count = 0;
    for (final g in shopping['groups'] as List) {
      for (final item in (g as Map)['items'] as List) {
        expect(find.text(item[0] as String), findsOneWidget);
        expect(find.text(item[2] as String), findsWidgets);
        count++;
      }
    }
    for (final item in shopping['check'] as List) {
      expect(find.text(item[0] as String), findsOneWidget);
    }
    expect(find.text('Sprawdź, czy masz'), findsOneWidget);
    expect(find.text('Kupione 0 z $count'), findsOneWidget);

    await tester.tap(find.text('Ryż biały (suchy)'));
    await settle(tester);
    expect(find.text('Kupione 1 z $count'), findsOneWidget);
    final checks = await tester.runAsync(() => db.watchChecks(1).first);
    expect(checks, {'ryz-bialy'});
  });
}
