# Mealprep

Osobista aplikacja do meal prepu: skaluje porcje pod Twoje makro, robi listę zakupów pod Biedronkę
i prowadzi przez sesję gotowania. Flutter i Supabase, zero złotych.

## Co jest w folderze

| Ścieżka | Co to |
|---|---|
| `docs/SPEC.md` | Specyfikacja: co aplikacja robi i jakie decyzje podjęliśmy |
| `docs/FORMAT_PRZEPISU.md` | Format przepisu i gotowa instrukcja do dyktowania przepisów Claude'owi |
| `docs/PRODUKTY.md` | Lista ID produktów do używania w przepisach |
| `data/products.json` | Baza produktów: makro na 100 g, działy, opakowania z Biedronki |
| `data/recipes/*.json` | Przepisy startowe |
| `tools/build_products.py` | Generuje `products.json` i `PRODUKTY.md`. Produkty edytuj tutaj |
| `tools/mealprep_proto.py` | Prototyp logiki: walidacja, skalowanie, lista zakupów, plan sesji |

## Szybkie polecenia (Python 3, bez dodatkowych bibliotek)

```bash
python3 tools/mealprep_proto.py validate   # czy przepisy są poprawne
python3 tools/mealprep_proto.py report     # jak każdy przepis trafia w makro
python3 tools/mealprep_proto.py demo       # przykładowa sesja: porcje, zakupy, plan gotowania
python3 tools/build_products.py            # po edycji listy produktów
python3 tools/export_test_fixture.py       # wyniki prototypu dla testów w Darcie (po zmianie danych/logiki)
```

## Status
- [x] Specyfikacja, format przepisu, baza produktów, przepisy startowe
- [x] Prototyp algorytmu (skalowanie, zakupy, wspólny plan sesji)
- [ ] Instalacja narzędzi na Macu (Xcode, Homebrew, Flutter)
- [ ] Etap 1: aplikacja Flutter na macOS z danymi lokalnymi
- [ ] Etap 2: Supabase i Android
- [ ] Etap 3: import przez wklejanie, skaner, iOS
