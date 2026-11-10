# Mealprep: kontekst dla Claude'a

Osobista aplikacja do meal prepu dla jednej osoby (właściciel repo). Pełna specyfikacja jest w `docs/SPEC.md` i trzeba ją przeczytać przed pracą.

## Kim jest użytkownik i jak z nim pracować
- Student mechatroniki. Zna podstawy C, Pythona i Arduino, ale nie pisał jeszcze aplikacji.
- Chce **mniej więcej rozumieć** kod: przy większych zmianach daj krótkie wyjaśnienie struktury i kluczowych decyzji, bez wykładów.
- Rozmawiamy **po polsku**. Interfejs aplikacji też jest po polsku.
- Zero kosztów: tylko darmowe narzędzia i darmowe plany.

## Ustalenia (szczegóły w docs/SPEC.md)
- **Flutter (Dart)**: najpierw macOS, potem Android, później iOS.
- Dane: lokalna baza SQLite (działa offline) i później synchronizacja z **Supabase (darmowy plan)**.
- Cele makro wpisywane ręcznie. Dzień treningowy dostaje +250 kcal z węglowodanów (wartość do ustawienia).
- Cel dnia dzielony **równo** na wszystkie posiłki tego dnia. Każdy skalowalny składnik skaluje się osobno, w zakresie min–max z przepisu.
- 2 sesje gotowania w tygodniu, każda na 3–4 dni. Jedno danie na każdy posiłek z prepu (zwykle 2–3 dziennie), do tego 1–2 posiłki na bieżąco.
  W aplikacji można wyłączyć posiłek na dany dzień (np. bez śniadania).
- Lista zakupów: działy w kolejności Biedronki, zaokrąglenie do opakowań, odhaczanie. Produkty z flagą `staple` trafiają do sekcji „sprawdź, czy masz".
- Tryb gotowania: suma do ugotowania, kroki po kolei z minutnikami, wspólny plan sesji (1 osoba, 4 palniki).
- Sprzęt: garnki, patelnia, blender. **Bez piekarnika.**
- Bez dzienniczka jedzenia. Skaner kodów kreskowych i iOS dopiero w wersji 2.

## Dane i logika
- `data/products.json`: baza produktów generowana przez `tools/build_products.py`. Produkty edytuj w tym skrypcie, nie w JSON-ie.
- `data/recipes/*.json`: przepisy w formacie `mealprep/1` (`docs/FORMAT_PRZEPISU.md`).
- `tools/mealprep_proto.py`: **wzorcowa implementacja logiki** (walidacja, solver skalowania, lista zakupów, harmonogram sesji).
  Logikę w Darcie przenieś z tego pliku 1:1 i dopisz testy, które dają takie same wyniki jak `python3 tools/mealprep_proto.py demo`.

## Kolejność prac i stan (aktualizuj po każdym etapie)
1. ✅ **Etap 1, macOS, dane lokalne**: gotowy i przetestowany przez użytkownika (listopad 2026).
2. ✅ **Etap 2**: Supabase (logowanie i synchronizacja) oraz build na Androida, gotowy i przetestowany (listopad 2026).
   Szczegóły: `docs/ETAP2.md`.
   Tor A (Android) gotowy: APK i emulator opisane w `docs/ANDROID.md`.
   Tor B (Supabase): synchronizacja Mac ↔ telefon działa; logowanie osobnym kontem z Authentication → Users.
3. Etap 3: import przepisów przez wklejanie JSON-a, wspólny plan sesji w interfejsie (logika już jest: `schedule.dart`), skaner, iOS.

Uwagi użytkownika do zrobienia przy okazji: dźwięk końca minutnika to placeholder do dostrojenia później.

## Jak zbudowana jest aplikacja
- `lib/logic/`: czysty Dart, bez Fluttera. Port 1:1 z prototypu: `models`, `validate`, `scaling` (solver, `pyRound`),
  `session` (`planSession`, `potShares`), `shopping`, `schedule`. Do tego `session_plan` (plan z datami → `toSession()`),
  `cooking` (sumy na partię, pudełka, tekst kroków, `StepTimer`), `defaults` (domyślne cele i posiłki).
- `lib/data/database.dart`: SQLite przez **drift** (schemat v4: `goals`, `meal_slots`, `sessions` z planem jako JSON,
  `shopping_checks`, `sync_meta`). Usunięcie sesji to nagrobek (`deleted`), odznaczenie to `checked = false`.
- Synchronizacja: `lib/logic/sync_merge.dart` (zasady), `lib/data/sync.dart` (silnik i kontroler),
  `lib/data/supabase_sync.dart` (Supabase), schemat serwera `supabase/schema.sql`. Uruchamianie z synchronizacją:
  `flutter run -d macos --dart-define-from-file=supabase.json` (bez tego aplikacja działa lokalnie). Po zmianie tabel: `dart run build_runner build`, podbij `schemaVersion` i dopisz `onUpgrade`
  (użytkownik ma już prawdziwą bazę na Macu, migracje muszą ją zachować; test migracji jest w `test/database_test.dart`).
- `lib/ui/`: `app_scope.dart` (InheritedWidget: baza, katalog, minutniki), `home_shell.dart` (4 zakładki: Plan, Zakupy,
  Gotowanie, Ustawienia; pasek dolny albo panel boczny), `cooking_timers.dart` (minutniki dla całej aplikacji),
  `widgets/session_view.dart` (wybór sesji dla Zakupów i Gotowania), ekrany w `screens/`.
- Zakupy i Gotowanie słuchają bazy przez strumienie drift (`watch...`), Plan i Ustawienia czytają raz.

## Testy i pułapki
- `tools/export_test_fixture.py` zapisuje wyniki prototypu do `test/fixtures/proto_expected.json`;
  `test/logic_parity_test.dart` porównuje z nimi Darta co do wartości. Po zmianie danych/prototypu wygeneruj fixture od nowa.
- Testy całej aplikacji pisz przez `testAppWidgets` i `settle` z `test/app_test_utils.dart`. Bez tego strumienie drift
  zostawiają timer i test się wywraca albo **zawiesza**. Gdy działa minutnik, nie używaj `pumpAndSettle` (nie skończy się),
  tylko `pump(Duration)`.
- `flutter test` puszczaj z `--timeout 40s` (na macOS nie ma polecenia `timeout`).
- Opis commita z polskimi cudzysłowami („…") zapisuj do pliku i używaj `git commit -F plik`, inaczej psuje się cytowanie w shellu.
- Baza aplikacji na Macu: `~/Library/Containers/pl.dera.mealprep/Data/Documents/mealprep.sqlite` (można podejrzeć `sqlite3`).
- Zrzuty ekranu macOS są zablokowane; wygląd UI sprawdza użytkownik.

Po każdym większym kroku uruchom `flutter analyze` i `flutter test`. Aplikację odpalaj przez `flutter run -d macos`.
Rób małe commity w gicie.
