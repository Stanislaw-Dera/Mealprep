import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mealprep/data/database.dart';
import 'package:mealprep/logic/models.dart';
import 'package:mealprep/main.dart';

import 'app_test_utils.dart';

void main() {
  late AppDatabase db;
  final catalog = Catalog.fromJson(
    jsonDecode(File('data/products.json').readAsStringSync())
        as Map<String, dynamic>,
    const [],
  );

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  /// Uruchamia aplikację na szerokim oknie (jak na Macu) i otwiera Ustawienia.
  Future<void> openSettings(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MealprepApp(db: db, catalog: catalog));
    await tester.tap(find.text('Ustawienia').first);
    // Baza odpowiada asynchronicznie, więc dajemy jej chwilę „prawdziwego" czasu.
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
  }

  Finder field(String label) => find.widgetWithText(TextFormField, label);

  testAppWidgets('pokazuje domyślne cele i podgląd na posiłek', (tester) async {
    await openSettings(tester);
    expect(find.text('3000'), findsOneWidget);
    expect(find.text('Drugie śniadanie'), findsOneWidget);
    // 3000 kcal / 5 posiłków
    expect(find.textContaining('Zwykły dzień: 600 kcal'), findsOneWidget);
    // Zapisz nieaktywne, dopóki nic nie zmienisz.
    final save = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Zapisz'),
    );
    expect(save.onPressed, isNull);
  });

  testAppWidgets('zmiana kalorii i zapis trafia do bazy', (tester) async {
    await openSettings(tester);
    await tester.enterText(field('Kalorie'), '3200');
    await tester.pump();
    expect(find.textContaining('Zwykły dzień: 640 kcal'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Zapisz'));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(find.text('Zapisano ustawienia'), findsOneWidget);

    final s = await tester.runAsync(db.loadSettings);
    expect(s!.target.kcal, 3200);
  });

  testAppWidgets('pusta nazwa posiłku blokuje zapis', (tester) async {
    await openSettings(tester);
    await tester.enterText(field('Posiłek 1'), '');
    await tester.pump(); // przerysuj, żeby „Zapisz" stał się aktywny
    await tester.tap(find.widgetWithText(FilledButton, 'Zapisz'));
    await tester.pumpAndSettle();
    expect(find.text('Podaj nazwę'), findsOneWidget);

    final slots = await tester.runAsync(db.loadMealSlots);
    expect(slots!.first.name, 'Śniadanie');
  });
}
