# Mealprep: specyfikacja

Osobista aplikacja do meal prepu, w stylu „policzonej szamy". Liczy się zdrowie i szybkość, nie kuchnia na pokaz.
Aplikacja jest tylko dla jednej osoby, więc stawiamy na prostotę, a nie na funkcje dla wielu użytkowników.

## Decyzje

| Temat | Decyzja |
|---|---|
| Technologia | **Flutter (Dart)**: jeden kod na macOS, Androida, a później iOS |
| Dane | Lokalna baza SQLite na urządzeniu (działa offline, np. w sklepie) i synchronizacja z **Supabase (darmowy plan)** |
| Koszt | 0 zł. Android: instalacja z pliku APK. iOS: decyzja przy zmianie telefonu (darmowe Apple ID wymaga przeinstalowania co 7 dni) |
| Język interfejsu | Polski. Motyw jasny lub ciemny, zgodnie z systemem |
| Jednostki | Gramy. Ryż, kasza i makaron podawane **na sucho**. Mięso surowe. Zaokrąglenie do 5 g |
| Precyzja makro | Wystarczy przybliżona (tolerancja ok. ±5–10%) |
| Sklep | Biedronka: typowe opakowania i kolejność działów |
| Sprzęt | Garnki, patelnia, blender. **Bez piekarnika** |

## Jak wygląda tydzień

- **Dwie sesje gotowania w tygodniu**, każda na 3–4 dni (np. niedziela i środa).
- W sesji gotuje się **jedno danie na każdy posiłek z prepu**, zwykle na 2–3 posiłki dziennie.
- Do tego dochodzą **1–2 posiłki „na bieżąco"** (np. śniadanie, które raz jem, a raz nie). Decyzję podejmuje się w aplikacji na dany dzień.
- **Dzień treningowy** (wspinaczka) dostaje dodatkowe kcal. Domyślnie +250 kcal z węglowodanów, wartość do ustawienia.

## Funkcje: wersja 1

### 1. Cele i ustawienia
- Ręcznie wpisywane kcal, białko (B), tłuszcz (T) i węglowodany (W) na zwykły dzień.
- Dodatek na dzień treningowy: liczba kcal i makroskładnik, z którego pochodzą.
- Konfigurowalna lista posiłków w dniu (nazwa, kolejność) i domyślne oznaczenie: z prepu albo na bieżąco.

### 2. Plan i skalowanie porcji
- Planujesz sesję: wybierasz dni, które obejmuje, i jedno danie na każdy posiłek z prepu.
- Dzień możesz oznaczyć jako treningowy. Możesz też wyłączyć posiłek na dany dzień (np. bez śniadania).
- **Cel dnia dzielony równo na wszystkie posiłki tego dnia.**
- **Każdy skalowalny składnik skaluje się osobno** (np. więcej kurczaka, mniej ryżu), żeby trafić jednocześnie w kcal, B, T i W.
  Przepis określa, które składniki są skalowalne i w jakich granicach (min–max g na porcję).
- Porcje mogą różnić się między dniami (np. w dzień treningowy więcej ryżu). Dlatego tryb gotowania pokazuje,
  jaką **część garnka** nałożyć do pudełka na dany dzień. Po zważeniu całości ugotowanej potrawy pokazuje też gramy na każde pudełko.

### 3. Lista zakupów
- Sumy surowych gramatur ze wszystkich posiłków sesji, opcjonalnie razem z posiłkami „na bieżąco".
- **Grupowanie po działach** w kolejności, w jakiej przechodzisz przez Biedronkę.
- **Zaokrąglenie do opakowań**, np. „potrzebujesz 380 g → 1 × ryż 400 g".
- Produkty, które zwykle są w domu (oliwa, przyprawy, sól), trafiają do osobnej sekcji „sprawdź, czy masz", zamiast na listę zakupów.
- **Odhaczanie w sklepie**, z synchronizacją między telefonem a Makiem.

### 4. Tryb gotowania
- **Suma do ugotowania**: łączne ilości każdego składnika na całą sesję.
- **Kroki po kolei**: jeden krok na ekranie, duży tekst, minutnik przy krokach z czasem.
- **Wspólny plan sesji**: kroki wszystkich dań sesji ułożone w jedną kolejność. Długie kroki „pasywne" (np. ryż się gotuje)
  startują wcześnie, a w międzyczasie wykonujesz kroki „aktywne" (krojenie). Plan uwzględnia jedną osobę i 4 palniki.

### 5. Przepisy i produkty
- Startowa baza przepisów (`data/recipes/`) i produktów (`data/products.json`) jest wbudowana w aplikację.
- Własne przepisy dodajesz w formacie JSON (`docs/FORMAT_PRZEPISU.md`): dyktujesz przepis Claude'owi, a on zapisuje go w tym formacie.
  Import:
  - **wklejenie tekstu w aplikacji** (ekran „Importuj": walidacja i podgląd makro przed zapisem),
  - **pliki w folderze** `data/recipes/`, wysyłane do bazy skryptem.
- Gdy przepis używa produktu, którego nie ma w bazie, import pokazuje błąd z listą brakujących produktów.
  Dane takiego produktu można dopisać w tym samym pliku JSON.

## Później (wersja 2+)
- Skaner kodów kreskowych (Open Food Facts) do dodawania produktów ze sklepu.
- iOS.
- Ewentualnie: spiżarnia, szacowany koszt listy, kalkulator zapotrzebowania.

## Poza zakresem
- Dzienniczek zjedzonych posiłków. Aplikacja tylko planuje.

## Kolejność budowy
1. **Etap 1, macOS, dane lokalne**: modele, wbudowana baza, cele, plan z skalowaniem, lista zakupów, tryb gotowania.
2. **Etap 2, synchronizacja**: konto Supabase, logowanie, synchronizacja planu i listy zakupów, build na Androida.
3. **Etap 3**: import z wklejania, wspólny plan sesji, skaner, iOS.

## Algorytm skalowania (zarys)
Dla każdego posiłku cel to `cel_dnia / liczba_posiłków_dnia`. Zmienne to gramatury składników skalowalnych,
w granicach `[min, max]` z przepisu. Składniki stałe tylko dodają swoje makro.
Minimalizujemy ważony błąd względny:

```
błąd = Σ w_m · ((makro_m(x) − cel_m) / cel_m)²     dla m ∈ {kcal, B, T, W}
wagi: kcal = 3, B = 2, T = 1, W = 1
```

Rozwiązanie: ograniczone najmniejsze kwadraty (2–5 zmiennych, problem liniowy) i zaokrąglenie do 5 g.
Prototyp i testy są w `tools/mealprep_proto.py`.
