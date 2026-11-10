# Etap 2: synchronizacja z Supabase i Android

Dwa niezależne tory. Można je robić w osobnych czatach, każdy na swojej gałęzi (np. `etap2-supabase`, `etap2-android`).
Oba mogą zmieniać `pubspec.yaml` i `android/app/src/main/AndroidManifest.xml`: przy łączeniu gałęzi sprawdź te pliki.

Stan na start (commit `c06de44`): Etap 1 gotowy na macOS, 41 testów przechodzi, `flutter analyze` czysty.

---

## Tor A: Android (build i instalacja z pliku APK)

### Po stronie użytkownika
- [x] Zainstalować **Android Studio** (darmowe), przejść pierwsze uruchomienie (instaluje Android SDK).
- [x] `flutter doctor --android-licenses` i sprawdzić `flutter doctor` (sekcja Android ma być ✓).
- [x] Telefon: włączyć opcje programisty i debugowanie USB (albo emulator z Android Studio).
      Użyty emulator; na telefon APK z pliku (`docs/ANDROID.md`).

### Do zrobienia
- [x] `flutter doctor` bez błędów dla Androida; aplikacja działa na emulatorze (Android 37).
- [x] Sprawdzić `applicationId` (`pl.dera.mealprep`), nazwę aplikacji „Mealprep", ikonę (może być domyślna na razie).
- [x] Uprawnienie `INTERNET` w `AndroidManifest.xml` dla wersji release (potrzebne do Supabase; debug ma je domyślnie).
- [x] Ekran nie wygasa w trakcie gotowania: pakiet `wakelock_plus` (darmowy), włączony tylko na ekranie dania.
- [x] Dźwięk minutnika (`audioplayers`, `assets/sounds/timer_done.wav`) działa na telefonie.
- [x] Wygląd na wąskim ekranie: dolny pasek nawigacji, karty dni w planie w jednej kolumnie, nic nie wychodzi poza ekran.
      Sprawdzić wszystkie 4 zakładki i ekran dania; poprawić to, co się nie mieści.
      (Poprawione: przyciski Zapisz/Cofnij w Ustawieniach i Start/Od nowa przy minutniku zawijają się.)
- [x] `flutter build apk --release` (podpis kluczem debug wystarczy do instalacji z pliku), instrukcja instalacji APK na telefonie:
      `docs/ANDROID.md`.
- [x] Testy: istniejące muszą przejść; test wąskiego ekranu `test/narrow_screen_test.dart`
      (360×740 i 390×844, także czcionka ×1.3).

Sprawdzone na emulatorze (wersja release): wszystkie zakładki, ekran dania, flaga `KEEP_SCREEN_ON` tylko na
ekranie dania, dźwięk końca minutnika (MediaPlayer bez błędów), aktualizacja APK zachowuje dane.
Do sprawdzenia na prawdziwym telefonie: głośność dźwięku. Teraz leci na kanale multimediów, więc przy
wyciszonych multimediach go nie słychać; ewentualnie przestawić na kanał alarmu. Minutnik nie budzi telefonu,
gdy aplikacja jest w tle (to by wymagało powiadomień, ewentualnie w Etapie 3).

---

## Tor B: Supabase (logowanie i synchronizacja)

### Po stronie użytkownika
- [x] Konto i projekt na supabase.com (darmowy plan).
- [x] Klucz publishable (w lokalnym `supabase.json`, poza gitem; wzór: `supabase.example.json`).
- [x] **Project URL** do `supabase.json` (`https://<id>.supabase.co`, w Project Settings → API).
- [x] Authentication → Users → *Add user* (e-mail i hasło, z *Auto Confirm User*). To osobne konto dla aplikacji,
      nie konto na supabase.com ani hasło do bazy.
- [x] Authentication → Sign In / Providers: wyłączyć *Allow new users to sign up* (sprawdzone: `disable_signup: true`).
- [x] Wkleić `supabase/schema.sql` w SQL Editor i uruchomić (Run).
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
- [x] SQL: tabele, indeksy, RLS, włączony Realtime (plik `supabase/schema.sql` w repo, użytkownik wkleja w SQL Editor).
- [x] Migracja lokalnej bazy do v4: `sessions` dostają `uuid` (globalny identyfikator) i `deleted`; `shopping_checks`
      dostają `checked` i `updated_at`; tabela kolejki zmian albo znaczniki „niewysłane”. Test migracji z v3.
- [x] Ekran logowania (e-mail + hasło) w Ustawieniach: stan „zalogowany jako…”, „Wyloguj”, „Synchronizuj teraz”,
      czas ostatniej synchronizacji, błędy po polsku.
- [x] Moduł synchronizacji (`lib/data/sync.dart`): wysyłka, pobieranie, scalanie, Realtime. Logika scalania jako czysty
      Dart z testami (bez sieci).
- [x] Pierwsze zalogowanie na urządzeniu z danymi: wysłać lokalne dane (Mac ma już cele i sesje).
- [x] Testy: scalanie konfliktów, nagrobki, migracja v3→v4; reszta testów nadal przechodzi.

### Jak to działa (zrobione)
- `lib/logic/sync_merge.dart`: zasady scalania (nowsza zmiana wygrywa, kursor pobierania z minutowym zakładem).
- `lib/data/database.dart` (schemat v4): sesje mają `uuid`, `deleted`, `dirty` i `updated_ms`; odhaczenia mają `checked`,
  `dirty`, `updated_ms`; tabela `sync_meta` trzyma czas zmiany ustawień, kursory i e-mail ostatniego konta.
  Zapis przez użytkownika ustawia `dirty`, zapis danych z serwera nie.
- `lib/data/sync.dart`: `SyncEngine` (wysyłka niewysłanych, pobranie zmian po `synced_at`) i `SyncController`
  (po zalogowaniu, sekundę po każdej lokalnej zmianie, po zdarzeniu Realtime, po powrocie do aplikacji; po błędzie ponowna
  próba za 30 s). `lib/data/supabase_sync.dart`: implementacja na Supabase.
- Serwer też pilnuje zasady „nowsza wygrywa" (wyzwalacz w `supabase/schema.sql`) i sam ustawia `synced_at`.
- Pierwsze logowanie danym kontem na urządzeniu: wszystkie lokalne dane idą do wysłania, pobierane jest wszystko.
  Domyślne cele nowej instalacji mają czas 0, więc nie nadpiszą prawdziwych celów z Maca.
- Testy: `test/sync_test.dart` (dwa urządzenia i serwer w pamięci: `test/sync_fakes.dart`), `test/sync_section_test.dart`,
  migracja v3→v4 w `test/database_test.dart`.

### Do sprawdzenia przez użytkownika
- [x] Po wklejeniu SQL i dodaniu użytkownika: zalogować się na Macu (Ustawienia → Synchronizacja), potem na emulatorze/telefonie;
      sesja i cele z Maca mają się pojawić na telefonie, odhaczenie na liście zakupów ma być widać na drugim urządzeniu.
      Sprawdzone 10 listopada 2026: Mac i telefon (APK release), sesje, cele i odhaczenia przechodzą w obie strony.
- APK z synchronizacją: `flutter build apk --release --dart-define-from-file=supabase.json`.
