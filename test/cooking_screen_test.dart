import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mealprep/data/database.dart';
import 'package:mealprep/logic/cooking.dart';
import 'package:mealprep/logic/models.dart';
import 'package:mealprep/logic/scaling.dart';
import 'package:mealprep/logic/session.dart';
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

  /// Sesja demo (Pon–Czw w prototypie), tu od dziś.
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
          .withDay(3, const PlanDay(training: true))
          .withRecipe('obiad', 'chili-con-carne')
          .withRecipe('kolacja', 'kurczak-curry-ryz');

  Future<void> openCooking(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      await db.saveSettings(settings);
      await db.saveSession(demoPlan());
    });
    await tester.pumpWidget(MealprepApp(db: db, catalog: catalog));
    await tester.tap(find.text('Gotowanie').first);
    await settle(tester);
  }

  final portions = planSession(settings, demoPlan().toSession(), catalog);
  double total(String recipe, String product) => recipeTotals(
    portions,
    recipe,
  ).firstWhere((a) => a.productId == product).g;

  testAppWidgets('dania sesji z sumami i kroki z wstawionymi gramami', (
    tester,
  ) async {
    await openCooking(tester);
    expect(find.text('Chili con carne z ryżem'), findsOneWidget);
    expect(find.text('Kurczak curry z ryżem i szpinakiem'), findsOneWidget);
    expect(find.text('485 g'), findsOneWidget); // mięso mielone, jak w zakupach

    await tester.tap(find.text('Gotuj krok po kroku').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('Na całą partię (4 pudełka)'), findsOneWidget);

    await tester.tap(find.text('Do kroków'));
    await tester.pumpAndSettle();
    expect(find.text('Krok 1 z 6'), findsOneWidget);
    final rice = formatGrams(total('chili-con-carne', 'ryz-bialy'));
    expect(
      find.text('Ugotuj $rice g ryżu.', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('15:00'), findsOneWidget);

    // Start minutnika ryżu, przejście dalej: minutnik widać na pasku.
    await tester.tap(find.text('Start'));
    await tester.pump();
    expect(find.text('Pauza'), findsOneWidget);
    await tester.tap(find.text('Dalej'));
    await tester.pump();
    expect(find.text('Krok 2 z 6'), findsOneWidget);
    expect(find.textContaining('Krok 1 · '), findsOneWidget);

    // Wyjście przy działającym minutniku pyta o zgodę.
    await tester.tap(find.byType(BackButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Minutniki dalej chodzą'), findsOneWidget);
    await tester.tap(find.text('Wyjdź'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Gotuj krok po kroku'), findsNWidgets(2));
  });

  testAppWidgets('gramy na pudełko po zważeniu potrawy', (tester) async {
    await openCooking(tester);
    await tester.tap(find.text('Gotuj krok po kroku').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pudełka'));
    await tester.pumpAndSettle();

    final boxes = boxesFor(portions, 'chili-con-carne');
    for (final b in boxes) {
      expect(find.text('${(b.share * 100).round()}% garnka'), findsWidgets);
    }
    await tester.enterText(find.byType(TextField), '2000');
    await tester.pump();
    for (final b in boxes) {
      expect(find.text('${(2000 * b.share).round()} g'), findsWidgets);
    }
  });
}
