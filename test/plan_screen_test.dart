import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mealprep/data/database.dart';
import 'package:mealprep/main.dart';

import 'app_test_utils.dart';
import 'test_data.dart';

void main() {
  late AppDatabase db;
  final catalog = loadCatalog();

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  testAppWidgets('nowa sesja, wybór dania i porcje na każdy dzień', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MealprepApp(db: db, catalog: catalog));
    await settle(tester);
    expect(
      find.textContaining('Nie masz jeszcze żadnej sesji'),
      findsOneWidget,
    );

    await tester.tap(find.text('Nowa sesja'));
    await settle(tester);
    expect(find.text('Dania z prepu'), findsOneWidget);
    expect(find.text('4 dni'), findsOneWidget);
    // Trzy posiłki z prepu w domyślnych ustawieniach, żaden jeszcze bez dania.
    expect(find.text('Wybierz danie'), findsNWidgets(3));

    await tester.tap(find.widgetWithText(ListTile, 'Obiad'));
    await settle(tester);
    expect(find.text('Pasują do: Obiad'), findsOneWidget);
    await tester.tap(find.text('Chili con carne z ryżem'));
    await settle(tester);

    // Porcja obiadu na każdy z 4 dni: linia makro i gramatury.
    expect(find.text('Chili con carne z ryżem'), findsOneWidget);
    expect(find.textContaining('Mięso mielone wołowe'), findsNWidgets(4));
    expect(find.textContaining('Chili con carne z ryżem: '), findsOneWidget);

    // Wyłączenie obiadu pierwszego dnia: zostają 3 porcje.
    await tester.tap(find.text('Obiad').at(1));
    await settle(tester);
    expect(find.textContaining('Mięso mielone wołowe'), findsNWidgets(3));
    expect(find.text('nie jem'), findsOneWidget);

    final saved = (await tester.runAsync(db.loadSessions))!;
    expect(saved.single.recipes, {'Obiad': 'chili-con-carne'});
    expect(saved.single.days.first.off, {'Obiad'});
  });
}
