import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mealprep/data/database.dart';
import 'package:mealprep/data/sync.dart';
import 'package:mealprep/logic/models.dart';
import 'package:mealprep/main.dart';

import 'app_test_utils.dart';
import 'sync_fakes.dart';

void main() {
  final catalog = Catalog.fromJson(
    jsonDecode(File('data/products.json').readAsStringSync())
        as Map<String, dynamic>,
    const [],
  );

  Future<void> openSettings(
    WidgetTester tester,
    SyncController? sync,
    AppDatabase db,
  ) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MealprepApp(db: db, catalog: catalog, sync: sync));
    await tester.tap(find.text('Ustawienia').first);
    await settle(tester);
  }

  testAppWidgets('bez supabase.json: informacja, że synchronizacja wyłączona', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await openSettings(tester, null, db);
    expect(find.textContaining('Synchronizacja wyłączona'), findsOneWidget);
  });

  testAppWidgets('logowanie, stan i wylogowanie', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final sync = SyncController(
      db: db,
      auth: FakeAuth(),
      remote: FakeRemote(),
      pushDelay: Duration.zero,
      retryDelay: const Duration(hours: 1),
    );
    await tester.runAsync(sync.start);
    addTearDown(() async {
      sync.dispose();
      await db.close();
    });
    await openSettings(tester, sync, db);

    final email = find.widgetWithText(TextField, 'E-mail');
    final password = find.widgetWithText(TextField, 'Hasło');
    await tester.enterText(email, 'ja@example.com');
    await tester.enterText(password, 'złe');
    await tester.tap(find.text('Zaloguj'));
    await settle(tester);
    expect(find.text('Zły e-mail albo hasło.'), findsOneWidget);

    await tester.enterText(password, 'dobre');
    await tester.tap(find.text('Zaloguj'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await settle(tester);
    expect(find.text('Zalogowano jako ja@example.com'), findsOneWidget);
    expect(
      find.textContaining('Ostatnia synchronizacja: dziś'),
      findsOneWidget,
    );

    await tester.tap(find.text('Wyloguj'));
    await settle(tester);
    expect(find.text('Zaloguj'), findsOneWidget);
  });
}
