// Wygląd na telefonie: wszystkie zakładki i ekran dania na wąskim ekranie.
// Test nie sprawdza treści, tylko to, że nic nie wychodzi poza ekran:
// przepełnienie (żółto-czarne paski) Flutter zgłasza jako błąd i test pada.
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
  final settings = Settings.fromJson(
    expected['settings'] as Map<String, dynamic>,
  );

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  SessionPlan demoPlan() =>
      SessionPlan.create(
            firstDay: dateOnly(DateTime.now()),
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
          .withRecipe('obiad', 'chili-con-carne')
          .withRecipe('kolacja', 'kurczak-curry-ryz');

  // Mały telefon (360 punktów szerokości) i powiększona czcionka systemowa,
  // którą wiele osób ma ustawioną na Androidzie.
  /// Przewija to, co jest na środku ekranu, do samego dołu.
  Future<void> scrollDown(WidgetTester tester, Size size) async {
    for (var i = 0; i < 6; i++) {
      await tester.dragFrom(size.center(Offset.zero), const Offset(0, -600));
      await tester.pump();
    }
  }

  for (final (size, scale) in [
    (const Size(360, 740), 1.0),
    (const Size(390, 844), 1.3),
    (const Size(360, 740), 1.3),
  ]) {
    testAppWidgets('nic nie wychodzi poza ekran ${size.width.toInt()}×'
        '${size.height.toInt()}, czcionka ×$scale', (tester) async {
      tester.view.physicalSize = size * 3;
      tester.view.devicePixelRatio = 3;
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.runAsync(() async {
        await db.saveSettings(settings);
        await db.saveSession(demoPlan());
      });
      await tester.pumpWidget(MealprepApp(db: db, catalog: catalog));
      await settle(tester);

      // Telefon: dolny pasek zamiast panelu bocznego.
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);

      // Plan i edytor sesji (przewinięty do końca).
      await tester.tap(find.byType(ListTile).first);
      await settle(tester);
      expect(find.text('Dania z prepu'), findsOneWidget);
      // Wybór dania dla obiadu i powrót do edytora.
      await tester.tap(find.widgetWithText(ListTile, 'obiad').first);
      await settle(tester);
      expect(find.text('Pasują do: obiad'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await settle(tester);
      await scrollDown(tester, size);
      await settle(tester);
      await tester.tap(find.byType(BackButton));
      await settle(tester);

      // Zakupy.
      await tester.tap(find.text('Zakupy').last);
      await settle(tester);
      await scrollDown(tester, size);
      await settle(tester);

      // Ustawienia.
      await tester.tap(find.text('Ustawienia').last);
      await settle(tester);
      await scrollDown(tester, size);
      await settle(tester);

      // Gotowanie i ekran dania: składniki, kroki z minutnikiem, pudełka.
      await tester.tap(find.text('Gotowanie').last);
      await settle(tester);
      await tester.ensureVisible(find.text('Gotuj krok po kroku').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gotuj krok po kroku').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kroki'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start'));
      await tester.pump();
      // Przy dużej czcionce „Dalej" jest niżej: trzeba przewinąć krok.
      await scrollDown(tester, size);
      await tester.tap(find.text('Dalej'));
      await tester.pump();
      await tester.tap(find.text('Pudełka'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), '2000');
      await tester.pump();
      await tester.tap(find.byType(BackButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      // Pasek minutników na górze listy dań.
      for (var i = 0; i < 6; i++) {
        await tester.dragFrom(size.center(Offset.zero), const Offset(0, 600));
        await tester.pump();
      }
      expect(find.textContaining('krok 1'), findsOneWidget);
    });
  }
}
