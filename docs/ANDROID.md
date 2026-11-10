# Android: budowanie i instalacja

## Zbudowanie pliku APK (na Macu)

```bash
flutter build apk --release --split-per-abi --dart-define-from-file=supabase.json
```

Flaga `--dart-define-from-file` wbudowuje dane projektu Supabase (synchronizacja); bez niej aplikacja działa tylko lokalnie.
Gotowy plik dla telefonu: `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` (ok. 20 MB).
`--split-per-abi` robi osobny plik dla każdego typu procesora. Prawie każdy współczesny telefon
(w tym Redmi Note 10 Pro) ma `arm64-v8a`. Bez tej flagi powstaje jeden plik `app-release.apk`
(ok. 60 MB), który działa wszędzie.

APK jest podpisany kluczem debug. Do instalacji z pliku na własnym telefonie to wystarcza,
do Sklepu Play by nie wystarczyło.

## Instalacja na telefonie (bez kabla i bez opcji programisty)

1. Przenieś plik `.apk` na telefon: np. wyślij go sobie na Google Drive, mailem albo przez Telegram/Messenger
   (AirDrop z Maca na Androida nie działa).
2. Na telefonie otwórz plik (z powiadomienia o pobraniu albo z aplikacji *Pliki* / *Menedżer plików*).
3. Android zapyta o zgodę na instalowanie aplikacji z tego źródła (np. z Chrome albo Dysku):
   *Ustawienia → Zezwól z tego źródła*, wróć i stuknij **Zainstaluj**.
   Na Xiaomi (MIUI/HyperOS) może się pojawić skanowanie zabezpieczeń i ostrzeżenie: wybierz
   „Zainstaluj mimo to”. Play Protect może pokazać „Nieznana aplikacja”: *Więcej szczegółów → Zainstaluj mimo to*.
4. Aplikacja **Mealprep** pojawi się na ekranie głównym.

**Nowa wersja:** zbuduj i zainstaluj nowy APK tak samo, a stara wersja zostanie zastąpiona.
Dane (cele, sesje, odhaczenia) zostają. Nie odinstalowuj aplikacji, bo usunięcie kasuje lokalną bazę.

## Kablem (USB) z Maca

Wymaga debugowania USB. Na Xiaomi: *Ustawienia → O telefonie →* stuknij 7 razy w **Wersja MIUI**
(albo **Wersja OS** w HyperOS), potem *Ustawienia → Ustawienia dodatkowe → Opcje programisty →
Debugowanie USB*. Na Xiaomi włącz tam też **Instaluj przez USB** (wymaga zalogowania do konta Mi).

```bash
flutter devices
```

```bash
flutter run -d <id telefonu> --dart-define-from-file=supabase.json
```

## Emulator

Emulator „Medium Phone API 37.0” z Android Studio. Domyślnie dostał 1 rdzeń i 2 GB RAM i Android sam się
w nim restartował (watchdog). Ustawione na 4 rdzenie i 4 GB w `~/.android/avd/Medium_Phone.avd/config.ini`.

```bash
flutter emulators --launch Medium_Phone_API_37.0
```

```bash
flutter run -d emulator-5554 --dart-define-from-file=supabase.json
```
