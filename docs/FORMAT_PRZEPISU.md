# Format przepisu `mealprep/1`

Każdy przepis to jeden obiekt JSON. Można go zapisać jako plik w `data/recipes/<id>.json` albo wkleić na ekranie „Importuj" w aplikacji.
Wklejana lista `[ {...}, {...} ]` importuje kilka przepisów naraz.

## Przykład

```json
{
  "format": "mealprep/1",
  "id": "kurczak-curry-ryz",
  "name": "Kurczak curry z ryżem i szpinakiem",
  "meal_types": ["obiad", "kolacja"],
  "prep": true,
  "fridge_days": 4,
  "time_min": 30,
  "equipment": ["garnek", "patelnia"],
  "tags": ["wysokobialkowe"],
  "ingredients": [
    { "product": "piers-kurczaka", "g": 150, "min": 80, "max": 260, "note": "w kostkę" },
    { "product": "ryz-bialy", "g": 70, "min": 20, "max": 160 },
    { "product": "szpinak-mrozony", "g": 100 },
    { "product": "mleczko-kokosowe-light", "g": 50 },
    { "product": "olej-rzepakowy", "g": 5, "min": 0, "max": 20 },
    { "product": "curry", "g": 2 }
  ],
  "steps": [
    { "text": "Ugotuj {ryz-bialy} ryżu w osolonej wodzie.", "min": 15, "passive": true, "burner": true },
    { "text": "W międzyczasie pokrój {piers-kurczaka} piersi w kostkę.", "min": 5, "after": [] },
    { "text": "Rozgrzej olej i smaż kurczaka z curry, aż się zetnie.", "min": 7, "burner": true },
    { "text": "Dodaj szpinak i mleczko kokosowe, duś pod przykryciem.", "min": 8, "passive": true, "burner": true },
    { "text": "Wymieszaj z ryżem albo podziel osobno do pudełek.", "min": 3, "after": [1, 4] }
  ]
}
```

## Pola przepisu

| Pole | Wymagane | Opis |
|---|---|---|
| `format` | tak | Zawsze `"mealprep/1"` |
| `id` | tak | Unikalny, małe litery i myślniki, bez polskich znaków (`kurczak-curry-ryz`) |
| `name` | tak | Nazwa wyświetlana |
| `meal_types` | tak | Lista z: `sniadanie`, `obiad`, `kolacja`, `przekaska` |
| `prep` | tak | `true`, jeśli danie nadaje się do pudełek na kilka dni. `false`, jeśli robi się je na bieżąco |
| `fridge_days` | gdy `prep` | Ile dni wytrzyma w lodówce (zwykle 3–4) |
| `time_min` | tak | Łączny czas przygotowania partii w minutach |
| `equipment` | nie | Z: `garnek`, `patelnia`, `blender`, `czajnik`, `mikrofalowka` |
| `tags` | nie | Dowolne, np. `wysokobialkowe`, `wege`, `tanie`, `bez-gotowania` |
| `ingredients` | tak | Lista składników, patrz niżej |
| `steps` | tak | Lista kroków, patrz niżej |
| `products` | nie | Definicje produktów, których nie ma jeszcze w bazie (format jak w `data/products.json`) |

## Składniki: ilości **na 1 porcję**

| Pole | Opis |
|---|---|
| `product` | ID produktu z bazy (`data/products.json`) |
| `g` | Gramy na 1 porcję, w stanie z listy zakupów: **ryż, kasza i makaron na sucho, mięso surowe** |
| `min`, `max` | Jeśli są podane, składnik jest **skalowalny**: algorytm dobierze gramaturę z tego zakresu. Bez nich składnik ma stałą ilość |
| `step` | Opcjonalny krok zaokrąglenia w gramach (domyślnie 5). Np. jajko `55` daje pełne jajka, kromka chleba `35` |
| `note` | Opcjonalna uwaga, np. „w kostkę" |

Wskazówki dotyczące skalowania:
- Skalowalne powinno być co najmniej jedno źródło białka, jedno węglowodanów i jedno tłuszczu. Wtedy algorytm trafi we wszystkie makro.
- Warzywa i przyprawy zwykle mają stałą ilość.
- Granice ustaw tak, żeby danie nadal było sobą: przy ryżu 20–160 g to rozsądny zakres, przy oleju 0–20 g.

## Kroki

Kroki opisują przygotowanie **całej partii** (3–4 porcji naraz). Wyświetlają się po kolei.

| Pole | Opis |
|---|---|
| `text` | Treść kroku. `{id-produktu}` wstawia łączną ilość tego produktu w sesji, np. „Ugotuj **280 g** ryżu" |
| `min` | Czas trwania w minutach |
| `passive` | `true`, jeśli krok nie zajmuje rąk (gotowanie, duszenie, studzenie). W tym czasie można robić inne rzeczy. Kroki z czasem dostają minutnik |
| `burner` | `true`, jeśli krok zajmuje palnik |
| `after` | Numery kroków (od 1), które muszą się skończyć wcześniej. **Domyślnie: poprzedni krok.** `[]` oznacza, że krok może zacząć się od razu (np. krojenie, gdy ryż się gotuje) |

Pola `passive`, `burner` i `after` pozwalają ułożyć **wspólny plan sesji**, czyli przeplatać kroki kilku dań.

---

## Instrukcja dla Claude'a (do wklejenia razem z przepisem)

> Zapisz ten przepis w formacie `mealprep/1` opisanym w dokumencie FORMAT_PRZEPISU.md w projekcie „Mealprep aplikacja".
> Używaj ID produktów z listy PRODUKTY.md. Jeśli jakiegoś produktu brakuje, dodaj jego definicję w polu `products`
> (makro na 100 g z tabel wartości odżywczych, dział sklepu, typowe opakowanie w Biedronce).
> Ilości podaj na 1 porcję, z ryżem, kaszą i makaronem na sucho oraz mięsem surowym.
> Oznacz jako skalowalne (`min`/`max`) główne źródła białka, węglowodanów i tłuszczu.
> Kroki pisz dla całej partii, krótko, z czasami oraz polami `passive`, `burner` i `after`.
> Zwróć sam JSON.
