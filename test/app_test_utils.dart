// Pomocnicze funkcje do testów całej aplikacji (MealprepApp).
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Jak `testWidgets`, ale po teście zdejmuje aplikację z ekranu.
///
/// Ekrany słuchają bazy przez strumienie drift. Po odłączeniu strumienia
/// drift odpala jeszcze timer zero-sekundowy, a test nie może się skończyć
/// z niewykonanym timerem. Dlatego zdejmujemy widgety i przesuwamy zegar
/// testu o 1 ms (`pump()` bez czasu zegara nie przesuwa).
void testAppWidgets(
  String description,
  Future<void> Function(WidgetTester tester) body,
) {
  testWidgets(description, (tester) async {
    try {
      await body(tester);
    } finally {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 1));
    }
  });
}

/// Daje bazie chwilę „prawdziwego" czasu, potem przerysowuje ekran.
Future<void> settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pumpAndSettle();
}
