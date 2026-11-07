"""Generuje data/products.json i docs/PRODUKTY.md z jednej tabeli.

Uruchom: python3 tools/build_products.py
Wartości na 100 g produktu w stanie z listy zakupów (ryż/kasza/makaron suche, mięso surowe,
puszki po odsączeniu). Węglowodany = przyswajalne (jak na etykietach UE).
pack = typowe opakowania w Biedronce w gramach ([] = na wagę / luzem).
piece_g = waga 1 sztuki (do wyświetlania "≈2 szt"), staple = zwykle jest w domu.
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

# Kolejność = kolejność przechodzenia przez sklep (do zmiany w ustawieniach aplikacji)
CATEGORIES = [
    ("warzywa-owoce", "Warzywa i owoce"),
    ("pieczywo", "Pieczywo"),
    ("suche", "Ryż, kasze, makarony, płatki"),
    ("puszki-sosy", "Puszki, sosy, przetwory"),
    ("orzechy-bakalie", "Orzechy, nasiona, bakalie"),
    ("przyprawy-tluszcze", "Przyprawy i tłuszcze"),
    ("mieso-ryby", "Mięso i ryby"),
    ("nabial", "Nabiał, jajka, tofu"),
    ("mrozonki", "Mrożonki"),
    ("inne", "Inne"),
]

S = True  # staple
P = [
    # id, nazwa, dział, kcal, B, T, W, opakowania [g], 1 szt [g], staple
    # --- warzywa i owoce ---
    ("brokul", "Brokuł", "warzywa-owoce", 34, 2.8, 0.4, 4.4, [], 450, False),
    ("kalafior", "Kalafior", "warzywa-owoce", 25, 1.9, 0.3, 3.0, [], 700, False),
    ("marchew", "Marchew", "warzywa-owoce", 41, 0.9, 0.2, 7.0, [1000], 80, False),
    ("cebula", "Cebula", "warzywa-owoce", 40, 1.1, 0.1, 7.6, [1000], 120, False),
    ("cebula-czerwona", "Cebula czerwona", "warzywa-owoce", 40, 1.1, 0.1, 7.6, [500], 120, False),
    ("czosnek", "Czosnek", "warzywa-owoce", 149, 6.4, 0.5, 31.0, [150], 5, False),
    ("por", "Por", "warzywa-owoce", 61, 1.5, 0.3, 12.4, [], 250, False),
    ("papryka-czerwona", "Papryka czerwona", "warzywa-owoce", 31, 1.0, 0.3, 4.6, [500], 200, False),
    ("pomidor", "Pomidor", "warzywa-owoce", 18, 0.9, 0.2, 2.6, [], 150, False),
    ("pomidorki-koktajlowe", "Pomidorki koktajlowe", "warzywa-owoce", 20, 0.9, 0.2, 3.0, [250], None, False),
    ("ogorek", "Ogórek", "warzywa-owoce", 15, 0.7, 0.1, 2.9, [], 300, False),
    ("cukinia", "Cukinia", "warzywa-owoce", 17, 1.2, 0.3, 2.1, [], 300, False),
    ("pieczarki", "Pieczarki", "warzywa-owoce", 22, 3.1, 0.3, 2.3, [500], None, False),
    ("szpinak-swiezy", "Szpinak świeży (baby)", "warzywa-owoce", 23, 2.9, 0.4, 1.4, [150], None, False),
    ("rukola", "Rukola", "warzywa-owoce", 25, 2.6, 0.7, 2.1, [100], None, False),
    ("mix-salat", "Mix sałat", "warzywa-owoce", 17, 1.4, 0.2, 2.0, [150], None, False),
    ("salata-lodowa", "Sałata lodowa", "warzywa-owoce", 14, 0.9, 0.1, 1.8, [], 500, False),
    ("kapusta-biala", "Kapusta biała", "warzywa-owoce", 25, 1.3, 0.1, 3.8, [], 1500, False),
    ("kapusta-pekinska", "Kapusta pekińska", "warzywa-owoce", 16, 1.2, 0.2, 2.2, [], 800, False),
    ("seler-naciowy", "Seler naciowy", "warzywa-owoce", 16, 0.7, 0.2, 1.4, [], 40, False),
    ("ziemniaki", "Ziemniaki", "warzywa-owoce", 77, 2.0, 0.1, 15.7, [2000], 150, False),
    ("bataty", "Bataty", "warzywa-owoce", 86, 1.6, 0.1, 17.1, [], 300, False),
    ("burak", "Burak", "warzywa-owoce", 43, 1.6, 0.2, 7.0, [1000], 150, False),
    ("awokado", "Awokado (miąższ)", "warzywa-owoce", 160, 2.0, 14.7, 1.8, [], 150, False),
    ("natka-pietruszki", "Natka pietruszki", "warzywa-owoce", 36, 3.0, 0.8, 3.0, [], 50, False),
    ("koperek", "Koperek", "warzywa-owoce", 43, 3.5, 1.1, 4.9, [], 50, False),
    ("szczypiorek", "Szczypiorek", "warzywa-owoce", 30, 3.3, 0.7, 1.9, [], 30, False),
    ("imbir", "Imbir świeży", "warzywa-owoce", 80, 1.8, 0.8, 15.8, [], 50, False),
    ("cytryna", "Cytryna", "warzywa-owoce", 29, 1.1, 0.3, 6.5, [], 100, False),
    ("banan", "Banan (bez skórki)", "warzywa-owoce", 89, 1.1, 0.3, 20.2, [], 120, False),
    ("jablko", "Jabłko", "warzywa-owoce", 52, 0.3, 0.2, 11.4, [], 180, False),
    ("pomarancza", "Pomarańcza (bez skórki)", "warzywa-owoce", 47, 0.9, 0.1, 9.4, [], 180, False),
    ("borowki", "Borówki amerykańskie", "warzywa-owoce", 57, 0.7, 0.3, 12.1, [125], None, False),
    # --- pieczywo ---
    ("chleb-zytni-pelnoziarnisty", "Chleb żytni pełnoziarnisty", "pieczywo", 220, 6.0, 1.5, 41.0, [500], 35, False),
    ("bulka-grahamka", "Bułka grahamka", "pieczywo", 250, 9.0, 2.5, 46.0, [], 80, False),
    ("tortilla-pszenna", "Tortilla pszenna 25 cm", "pieczywo", 310, 8.5, 7.5, 50.0, [370], 62, False),
    ("tortilla-pelnoziarnista", "Tortilla pełnoziarnista", "pieczywo", 290, 9.0, 6.5, 44.0, [370], 62, False),
    ("wafle-ryzowe", "Wafle ryżowe", "pieczywo", 390, 8.0, 3.0, 81.0, [130], 8, False),
    # --- suche ---
    ("ryz-bialy", "Ryż biały (suchy)", "suche", 350, 7.0, 0.7, 78.0, [400, 1000], None, False),
    ("ryz-basmati", "Ryż basmati (suchy)", "suche", 352, 8.0, 0.8, 77.0, [500, 1000], None, False),
    ("ryz-brazowy", "Ryż brązowy (suchy)", "suche", 355, 7.5, 2.7, 73.0, [400], None, False),
    ("kasza-gryczana", "Kasza gryczana (sucha)", "suche", 345, 12.6, 3.1, 65.0, [400], None, False),
    ("kasza-jaglana", "Kasza jaglana (sucha)", "suche", 360, 10.5, 2.9, 69.0, [400], None, False),
    ("kasza-bulgur", "Kasza bulgur (sucha)", "suche", 342, 12.3, 1.3, 64.0, [400], None, False),
    ("kasza-peczak", "Kasza pęczak (sucha)", "suche", 330, 9.7, 1.9, 66.0, [400], None, False),
    ("kuskus", "Kuskus (suchy)", "suche", 360, 12.8, 1.5, 72.0, [400], None, False),
    ("quinoa", "Komosa ryżowa (sucha)", "suche", 368, 14.1, 6.1, 57.0, [250], None, False),
    ("makaron-pszenny", "Makaron pszenny (suchy)", "suche", 355, 12.5, 1.5, 71.0, [500], None, False),
    ("makaron-pelnoziarnisty", "Makaron pełnoziarnisty (suchy)", "suche", 350, 13.0, 2.5, 63.0, [500], None, False),
    ("makaron-ryzowy", "Makaron ryżowy (suchy)", "suche", 360, 6.5, 0.6, 80.0, [200], None, False),
    ("platki-owsiane", "Płatki owsiane", "suche", 372, 13.5, 7.0, 59.0, [500], None, False),
    ("soczewica-czerwona", "Soczewica czerwona (sucha)", "suche", 340, 25.0, 1.5, 49.0, [400], None, False),
    ("maka-pszenna", "Mąka pszenna", "suche", 340, 10.0, 1.2, 71.0, [1000], None, S),
    # --- puszki, sosy ---
    ("passata", "Passata pomidorowa", "puszki-sosy", 32, 1.4, 0.2, 5.5, [500, 690], None, False),
    ("pomidory-krojone", "Pomidory krojone (puszka)", "puszki-sosy", 22, 1.2, 0.2, 3.5, [400], None, False),
    ("koncentrat-pomidorowy", "Koncentrat pomidorowy", "puszki-sosy", 82, 4.3, 0.5, 14.0, [80], None, False),
    ("fasola-czerwona", "Fasola czerwona (puszka, po odsączeniu)", "puszki-sosy", 100, 7.0, 0.5, 13.0, [240], None, False),
    ("fasola-biala", "Fasola biała (puszka, po odsączeniu)", "puszki-sosy", 95, 6.5, 0.5, 12.5, [240], None, False),
    ("ciecierzyca", "Ciecierzyca (puszka, po odsączeniu)", "puszki-sosy", 120, 7.0, 2.5, 14.0, [240], None, False),
    ("kukurydza", "Kukurydza (puszka, po odsączeniu)", "puszki-sosy", 80, 2.8, 1.5, 12.5, [285], None, False),
    ("tunczyk-wlasny", "Tuńczyk w sosie własnym (po odsączeniu)", "puszki-sosy", 105, 24.0, 1.0, 0.0, [120], None, False),
    ("mleczko-kokosowe-light", "Mleczko kokosowe light", "puszki-sosy", 85, 0.8, 8.5, 1.5, [400], None, False),
    ("mleczko-kokosowe", "Mleczko kokosowe", "puszki-sosy", 180, 1.5, 18.0, 2.5, [400], None, False),
    ("sos-sojowy", "Sos sojowy", "puszki-sosy", 60, 8.0, 0.1, 6.0, [150], None, S),
    ("musztarda", "Musztarda", "puszki-sosy", 120, 6.0, 7.0, 6.0, [190], None, S),
    ("ocet-balsamiczny", "Ocet balsamiczny", "puszki-sosy", 88, 0.5, 0.0, 17.0, [250], None, S),
    ("hummus", "Hummus", "nabial", 250, 7.0, 20.0, 9.0, [200], None, False),
    # --- orzechy, nasiona ---
    ("maslo-orzechowe", "Masło orzechowe 100%", "orzechy-bakalie", 600, 25.0, 50.0, 12.0, [340], None, False),
    ("orzechy-wloskie", "Orzechy włoskie", "orzechy-bakalie", 654, 15.0, 65.0, 7.0, [200], None, False),
    ("migdaly", "Migdały", "orzechy-bakalie", 580, 21.0, 50.0, 9.0, [200], None, False),
    ("nasiona-chia", "Nasiona chia", "orzechy-bakalie", 486, 16.5, 30.7, 7.7, [200], None, False),
    ("siemie-lniane", "Siemię lniane", "orzechy-bakalie", 534, 18.0, 42.0, 1.6, [250], None, False),
    ("pestki-dyni", "Pestki dyni", "orzechy-bakalie", 559, 30.0, 49.0, 5.0, [150], None, False),
    ("slonecznik", "Słonecznik łuskany", "orzechy-bakalie", 584, 21.0, 51.0, 11.0, [200], None, False),
    ("sezam", "Sezam", "orzechy-bakalie", 573, 17.7, 50.0, 12.0, [100], None, False),
    ("rodzynki", "Rodzynki", "orzechy-bakalie", 299, 3.0, 0.5, 75.0, [200], None, False),
    # --- przyprawy i tłuszcze ---
    ("oliwa", "Oliwa z oliwek", "przyprawy-tluszcze", 884, 0.0, 100.0, 0.0, [500, 1000], None, S),
    ("olej-rzepakowy", "Olej rzepakowy", "przyprawy-tluszcze", 884, 0.0, 100.0, 0.0, [1000], None, S),
    ("miod", "Miód", "przyprawy-tluszcze", 320, 0.3, 0.0, 80.0, [400], None, S),
    ("kakao", "Kakao naturalne", "przyprawy-tluszcze", 228, 19.6, 13.7, 12.0, [150], None, S),
    ("sol", "Sól", "przyprawy-tluszcze", 0, 0.0, 0.0, 0.0, [1000], None, S),
    ("pieprz", "Pieprz czarny", "przyprawy-tluszcze", 251, 10.4, 3.3, 39.0, [20], None, S),
    ("papryka-slodka", "Papryka słodka mielona", "przyprawy-tluszcze", 282, 14.0, 13.0, 20.0, [20], None, S),
    ("papryka-wedzona", "Papryka wędzona mielona", "przyprawy-tluszcze", 282, 14.0, 13.0, 20.0, [20], None, S),
    ("curry", "Curry (przyprawa)", "przyprawy-tluszcze", 325, 14.0, 14.0, 25.0, [20], None, S),
    ("kumin", "Kumin mielony", "przyprawy-tluszcze", 375, 18.0, 22.0, 34.0, [20], None, S),
    ("kurkuma", "Kurkuma", "przyprawy-tluszcze", 312, 9.7, 3.3, 45.0, [20], None, S),
    ("cynamon", "Cynamon", "przyprawy-tluszcze", 247, 4.0, 1.2, 27.0, [20], None, S),
    ("oregano", "Oregano suszone", "przyprawy-tluszcze", 265, 9.0, 4.3, 27.0, [10], None, S),
    ("bazylia-suszona", "Bazylia suszona", "przyprawy-tluszcze", 233, 23.0, 4.0, 10.0, [10], None, S),
    ("ziola-prowansalskie", "Zioła prowansalskie", "przyprawy-tluszcze", 270, 9.0, 5.0, 30.0, [10], None, S),
    ("czosnek-granulowany", "Czosnek granulowany", "przyprawy-tluszcze", 330, 16.5, 0.7, 63.0, [20], None, S),
    ("chili-platki", "Chili płatki", "przyprawy-tluszcze", 318, 12.0, 17.0, 22.0, [15], None, S),
    # --- mięso i ryby ---
    ("piers-kurczaka", "Pierś z kurczaka (surowa)", "mieso-ryby", 110, 23.0, 1.5, 0.0, [500, 1000], None, False),
    ("filet-z-udka", "Filet z udka kurczaka (surowy)", "mieso-ryby", 121, 19.7, 4.1, 0.0, [500], None, False),
    ("piers-indyka", "Pierś z indyka (surowa)", "mieso-ryby", 105, 23.5, 1.0, 0.0, [500], None, False),
    ("mielone-indyk", "Mięso mielone z indyka", "mieso-ryby", 140, 19.0, 7.0, 0.0, [500], None, False),
    ("mielone-wolowe", "Mięso mielone wołowe", "mieso-ryby", 210, 19.0, 15.0, 0.0, [400], None, False),
    ("schab", "Schab bez kości (surowy)", "mieso-ryby", 145, 21.0, 6.5, 0.0, [], None, False),
    ("losos", "Łosoś, filet (surowy)", "mieso-ryby", 200, 20.0, 13.0, 0.0, [250], None, False),
    ("szynka-z-indyka", "Szynka z indyka (wędlina)", "mieso-ryby", 100, 19.0, 2.0, 2.0, [150], None, False),
    # --- nabiał ---
    ("jajko", "Jajko (bez skorupki)", "nabial", 140, 12.5, 9.7, 0.7, [330, 550], 55, False),
    ("skyr", "Skyr naturalny", "nabial", 63, 11.0, 0.2, 4.0, [150], None, False),
    ("jogurt-grecki", "Jogurt typu greckiego", "nabial", 120, 4.0, 10.0, 4.0, [400], None, False),
    ("jogurt-naturalny", "Jogurt naturalny 2%", "nabial", 60, 4.3, 2.0, 6.0, [400], None, False),
    ("twarog-poltlusty", "Twaróg półtłusty", "nabial", 133, 18.0, 4.0, 3.7, [250], None, False),
    ("twarog-chudy", "Twaróg chudy", "nabial", 99, 19.8, 0.5, 3.5, [250], None, False),
    ("serek-wiejski", "Serek wiejski", "nabial", 98, 11.0, 5.0, 2.0, [200], None, False),
    ("mleko", "Mleko 2%", "nabial", 50, 3.2, 2.0, 4.8, [1000], None, False),
    ("kefir", "Kefir", "nabial", 50, 3.4, 2.0, 4.5, [400], None, False),
    ("mozzarella-light", "Mozzarella light", "nabial", 160, 19.0, 9.0, 1.0, [125], None, False),
    ("ser-zolty", "Ser żółty (gouda)", "nabial", 356, 25.0, 27.4, 0.0, [150], None, False),
    ("ser-feta", "Ser feta", "nabial", 265, 14.0, 21.0, 1.5, [200], None, False),
    ("parmezan", "Grana Padano / parmezan", "nabial", 392, 33.0, 28.0, 0.0, [100], None, False),
    ("smietana-12", "Śmietana 12%", "nabial", 133, 2.5, 12.0, 3.5, [200, 400], None, False),
    ("maslo", "Masło", "nabial", 735, 0.7, 81.0, 0.6, [200], None, False),
    ("tofu", "Tofu naturalne", "nabial", 120, 12.5, 7.0, 1.5, [180], None, False),
    # --- mrożonki ---
    ("mieszanka-chinska", "Warzywa na patelnię (mieszanka chińska)", "mrozonki", 35, 1.8, 0.3, 5.0, [450], None, False),
    ("mieszanka-meksykanska", "Mieszanka meksykańska", "mrozonki", 70, 3.5, 0.5, 11.0, [450], None, False),
    ("brokul-mrozony", "Brokuł mrożony", "mrozonki", 28, 2.8, 0.4, 3.0, [450], None, False),
    ("kalafior-mrozony", "Kalafior mrożony", "mrozonki", 25, 2.0, 0.3, 3.0, [450], None, False),
    ("szpinak-mrozony", "Szpinak mrożony (liście)", "mrozonki", 23, 2.9, 0.4, 0.8, [450], None, False),
    ("fasolka-szparagowa", "Fasolka szparagowa mrożona", "mrozonki", 31, 1.8, 0.2, 4.3, [450], None, False),
    ("groszek", "Groszek zielony mrożony", "mrozonki", 77, 5.4, 0.4, 10.0, [450], None, False),
    ("owoce-lesne", "Owoce leśne mrożone", "mrozonki", 45, 0.9, 0.3, 8.5, [450], None, False),
    ("truskawki-mrozone", "Truskawki mrożone", "mrozonki", 32, 0.7, 0.3, 6.0, [450], None, False),
    ("mango-mrozone", "Mango mrożone", "mrozonki", 60, 0.8, 0.4, 13.5, [450], None, False),
    ("dorsz", "Dorsz, filet mrożony", "mrozonki", 77, 17.5, 0.7, 0.0, [400], None, False),
    ("krewetki", "Krewetki mrożone (obrane)", "mrozonki", 75, 17.0, 0.6, 0.0, [400], None, False),
    # --- inne ---
    ("odzywka-bialkowa", "Odżywka białkowa (WPC)", "inne", 380, 75.0, 6.0, 7.0, [700], None, S),
]


def main():
    cat_ids = {c for c, _ in CATEGORIES}
    seen = set()
    products = []
    for pid, name, cat, kcal, p, f, c, pack, piece, staple in P:
        assert pid not in seen, f"duplikat id {pid}"
        assert cat in cat_ids, f"{pid}: nieznany dział {cat}"
        seen.add(pid)
        d = {"id": pid, "name": name, "cat": cat, "kcal": kcal, "p": p, "f": f, "c": c, "pack": pack}
        if piece:
            d["piece_g"] = piece
        if staple:
            d["staple"] = True
        products.append(d)

    out = {
        "format": "mealprep-products/1",
        "categories": [{"id": c, "name": n} for c, n in CATEGORIES],
        "products": products,
    }
    # jeden produkt na linię = czytelne diffy w gicie
    lines = ['{', f'  "format": "{out["format"]}",', '  "categories": [']
    lines += [f"    {json.dumps(c, ensure_ascii=False)}," for c in out["categories"]]
    lines[-1] = lines[-1].rstrip(",")
    lines += ["  ],", '  "products": [']
    lines += [f"    {json.dumps(p, ensure_ascii=False)}," for p in products]
    lines[-1] = lines[-1].rstrip(",")
    lines += ["  ]", "}", ""]
    text = "\n".join(lines)
    json.loads(text)  # sanity
    (ROOT / "data" / "products.json").write_text(text, encoding="utf-8")

    md = ["# Produkty w bazie\n",
          "Lista ID do używania w przepisach (`\"product\": \"<id>\"`). Wartości na 100 g: kcal / B / T / W.\n"]
    for cid, cname in CATEGORIES:
        items = [p for p in products if p["cat"] == cid]
        if not items:
            continue
        md.append(f"\n## {cname}\n")
        for p in items:
            md.append(f"- `{p['id']}`: {p['name']} ({p['kcal']} / {p['p']} / {p['f']} / {p['c']})")
    (ROOT / "docs" / "PRODUKTY.md").write_text("\n".join(md) + "\n", encoding="utf-8")
    print(f"OK: {len(products)} produktów")


if __name__ == "__main__":
    main()
