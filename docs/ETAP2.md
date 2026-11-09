# Etap 2: synchronizacja z Supabase i Android

Dwa niezależne tory. Można je robić w osobnych czatach, każdy na swojej gałęzi (np. `etap2-supabase`, `etap2-android`).
Oba mogą zmieniać `pubspec.yaml` i `android/app/src/main/AndroidManifest.xml`: przy łączeniu gałęzi sprawdź te pliki.

Stan na start (commit `c06de44`): Etap 1 gotowy na macOS, 41 testów przechodzi, `flutter analyze` czysty.

---

## Tor A: Android (build i instalacja z pliku APK)

### Po stronie użytkownika
- [ ] Zainstalować **Android Studio** (darmowe), przejść pierwsze uruchomienie (instaluje Android SDK).
- [ ] `flutter doctor --android-licenses` i sprawdzić `flutter doctor` (sekcja Android ma być ✓).
- [ ] Telefon: włączyć opcje programisty i debugowanie USB (albo emulator z Android Studio).

### Do zrobienia
- [ ] `flutter doctor` bez błędów dla Androida; `flutter run -d <telefon>` działa.
- [ ] Sprawdzić `applicationId` (`pl.dera.mealprep`), nazwę aplikacji „Mealprep", ikonę (może być domyślna na razie).
- [ ] Uprawnienie `INTERNET` w `AndroidManifest.xml` dla wersji release (potrzebne do Supabase; debug ma je domyślnie).
- [ ] Ekran nie wygasa w trakcie gotowania: pakiet `wakelock_plus` (darmowy), włączony tylko na ekranie dania.
- [ ] Dźwięk minutnika (`audioplayers`, `assets/sounds/timer_done.wav`) działa na telefonie.
- [ ] Wygląd na wąskim ekranie: dolny pasek nawigacji, karty dni w planie w jednej kolumnie, nic nie wychodzi poza ekran.
      Sprawdzić wszystkie 4 zakładki i ekran dania; poprawić to, co się nie mieści.
- [ ] `flutter build apk --release` (podpis kluczem debug wystarczy do instalacji z pliku), instrukcja instalacji APK na telefonie.
- [ ] Testy: istniejące muszą przejść; ewentualnie test widgetu na wąskim ekranie (np. 390×844).

---

## Tor B: Supabase (logowanie i synchronizacja)

### Po stronie użytkownika
- [x] Konto i projekt na supabase.com (darmowy plan).
- [x] Klucz publishable (w lokalnym `supabase.json`, poza gitem; wzór: `supabase.example.json`).
- [ ] **Project URL** do `supabase.json` (`https://<id>.supabase.co`, w Project Settings → API).
- [ ] Authentication → Users → *Add user* (e-mail i hasło).
- [ ] Authentication → Sign In / Providers: wyłączyć *Allow new users to sign up*.
- [ ] Wkleić SQL ze schematem (przygotuje Claude) w SQL Editor.
- Nigdy nie podawać Claude'owi klucza `service_role`/`secret` ani hasła do bazy.

### Założenia
- **Najpierw lokalnie**: aplikacja działa offline jak dziś. Logowanie jest tylko po to, żeby synchronizować.
- Konfiguracja przy budowaniu: `flutter run -d macos --dart-define-from-file=supabase.json`
  (w kodzie `String.fromEnvironment('SUPABASE_URL')`). Bez pliku aplikacja działa bez synchronizacji.
- Pakiet `supabase_flutter`. macOS: w `macos/Runner/*.entitlements` dodać `com.apple.security.network.client`
  (sandbox blokuje sieć). Android: `INTERNET` (tor A).
- Jeden użytkownik, ale tabele z `user_id` i **RLS** (`user_id = auth.uid()`), żeby klucz publishable nie dawał dostępu do danych.

### Co synchronizujemy
| Lokalnie (drift) | W Supabase | Uwagi |
|---|---|---|
| `goals` + `meal_slots` | `settings` (1 wiersz: `data jsonb`) | ustawienia jako jeden obiekt |
| `sessions` | `sessions` (`id uuid`, `first_day`, `data jsonb`, `updated_at`, `deleted`) | plan jako JSON jak lokalnie |
| `shopping_checks` | `shopping_checks` (`session_id uuid`, `product_id`, `checked`, `updated_at`) | odhaczenia; na żywo przez Realtime |

### Zasady synchronizacji
- Każdy wiersz ma `updated_at`; przy konflikcie **wygrywa nowsza zmiana** (last write wins).
- Usunięcia jako „nagrobki” (`deleted = true`), żeby drugie urządzenie wiedziało, że sesja zniknęła.
- Odznaczenie na liście = wiersz z `checked = false` (a nie usunięcie), z tego samego powodu.
- Wysyłka: po każdej lokalnej zmianie (kolejka zmian niewysłanych, ponawiana po odzyskaniu sieci).
- Pobieranie: przy starcie i po zalogowaniu (wszystko nowsze niż ostatnia synchronizacja) + **Realtime** na `shopping_checks`
  (w sklepie odhaczenie z telefonu od razu widać na Macu) i na `sessions`.

### Do zrobienia
- [ ] SQL: tabele, indeksy, RLS, włączony Realtime (plik `supabase/schema.sql` w repo, użytkownik wkleja w SQL Editor).
- [ ] Migracja lokalnej bazy do v4: `sessions` dostają `uuid` (globalny identyfikator) i `deleted`; `shopping_checks`
      dostają `checked` i `updated_at`; tabela kolejki zmian albo znaczniki „niewysłane”. Test migracji z v3.
- [ ] Ekran logowania (e-mail + hasło) w Ustawieniach: stan „zalogowany jako…”, „Wyloguj”, „Synchronizuj teraz”,
      czas ostatniej synchronizacji, błędy po polsku.
- [ ] Moduł synchronizacji (`lib/data/sync.dart`): wysyłka, pobieranie, scalanie, Realtime. Logika scalania jako czysty
      Dart z testami (bez sieci).
- [ ] Pierwsze zalogowanie na urządzeniu z danymi: wysłać lokalne dane (Mac ma już cele i sesje).
- [ ] Testy: scalanie konfliktów, nagrobki, migracja v3→v4; reszta testów nadal przechodzi.
