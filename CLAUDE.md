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

## Kolejność prac
1. **Etap 1, macOS, dane lokalne**: `flutter create` (platformy: macos, android, ios), modele, wczytanie danych z assets, ekran celów,
   planowanie sesji ze skalowaniem, lista zakupów, tryb gotowania.
2. Etap 2: Supabase (logowanie i synchronizacja planu oraz listy), build na Androida.
3. Etap 3: import przepisów przez wklejanie JSON-a, wspólny plan sesji w interfejsie, skaner, iOS.

Po każdym większym kroku uruchom `flutter analyze` i `flutter test`. Aplikację odpalaj przez `flutter run -d macos`.
Rób małe commity w gicie.
