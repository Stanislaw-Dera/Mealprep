"""Prototyp logiki aplikacji Mealprep (do przeniesienia 1:1 do Darta).

  python3 tools/mealprep_proto.py validate      # sprawdza przepisy i produkty
  python3 tools/mealprep_proto.py report        # jak każdy przepis trafia w przykładowe cele
  python3 tools/mealprep_proto.py demo          # przykładowa sesja: porcje, zakupy, plan gotowania

Celowo bez numpy/scipy: solver to prosty "projected coordinate descent",
który da się łatwo przepisać na Darta.
"""
import itertools
import json
import math
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MACROS = ("kcal", "p", "f", "c")
WEIGHTS = {"kcal": 3.0, "p": 2.0, "f": 1.0, "c": 1.0}
ROUND_G = 5
MEAL_TYPES = {"sniadanie", "obiad", "kolacja", "przekaska"}


# ---------------------------------------------------------------- dane
def load():
    pdata = json.loads((ROOT / "data/products.json").read_text(encoding="utf-8"))
    products = {p["id"]: p for p in pdata["products"]}
    cats = [c["id"] for c in pdata["categories"]]
    recipes = {}
    for f in sorted((ROOT / "data/recipes").glob("*.json")):
        r = json.loads(f.read_text(encoding="utf-8"))
        for extra in r.get("products", []):
            products.setdefault(extra["id"], extra)
        recipes[r["id"]] = r
    return products, cats, recipes


def validate_recipe(r, products):
    """Zwraca listę błędów (pusta = OK). Ta sama logika pójdzie do ekranu 'Importuj'."""
    e = []
    for key in ("format", "id", "name", "meal_types", "prep", "time_min", "ingredients", "steps"):
        if key not in r:
            e.append(f"brak pola '{key}'")
    if e:
        return e
    if r["format"] != "mealprep/1":
        e.append("format musi być 'mealprep/1'")
    if not set(r["meal_types"]) <= MEAL_TYPES:
        e.append(f"nieznane meal_types: {set(r['meal_types']) - MEAL_TYPES}")
    if r["prep"] and "fridge_days" not in r:
        e.append("danie do prepu potrzebuje 'fridge_days'")
    scal = []
    for ing in r["ingredients"]:
        pid = ing.get("product")
        if pid not in products:
            e.append(f"nieznany produkt '{pid}'")
            continue
        if ("min" in ing) != ("max" in ing):
            e.append(f"{pid}: podaj oba 'min' i 'max'")
        if "min" in ing:
            if not ing["min"] <= ing["g"] <= ing["max"]:
                e.append(f"{pid}: g={ing['g']} poza zakresem {ing['min']}-{ing['max']}")
            scal.append(products[pid])
    # czy jest czym sterować białkiem, tłuszczem i węglami
    if scal:
        # produkt "steruje" makroskładnikiem, jeśli daje ≥30% jego energii
        have = set()
        for p in scal:
            en = {"p": 4 * p["p"], "f": 9 * p["f"], "c": 4 * p["c"]}
            tot = sum(en.values()) or 1
            have |= {m for m, v in en.items() if v / tot >= 0.3}
        missing = {"p": "białka", "f": "tłuszczu", "c": "węglowodanów"}
        for m in ("p", "f", "c"):
            if m not in have:
                e.append(f"uwaga: brak skalowalnego źródła {missing[m]}")
    else:
        e.append("uwaga: brak składników skalowalnych - porcja będzie stała")
    n = len(r["steps"])
    for i, s in enumerate(r["steps"], 1):
        if "text" not in s or "min" not in s:
            e.append(f"krok {i}: wymagane 'text' i 'min'")
        for a in s.get("after", []):
            if not (1 <= a < i):
                e.append(f"krok {i}: 'after' może wskazywać tylko wcześniejsze kroki (jest {a})")
    return e


# ---------------------------------------------------------------- makro
def macros_of(items, products):
    """items: lista (product_id, gramy) -> dict makro"""
    tot = dict.fromkeys(MACROS, 0.0)
    for pid, g in items:
        p = products[pid]
        for m in MACROS:
            tot[m] += p[m] * g / 100
    return tot


def scale_recipe(r, products, target, reg=0.02):
    """Dobiera gramatury składników skalowalnych pod cel posiłku.

    Minimalizuje  Σ w_m ((makro_m - cel_m)/cel_m)²  +  reg · Σ ((x_i - g_i)/s_i)²
    przy  min_i ≤ x_i ≤ max_i. Regularyzacja trzyma proporcje blisko przepisu,
    gdy kilka rozwiązań jest równie dobrych.
    Zwraca listę (product_id, gramy) dla wszystkich składników.
    """
    fixed = [(i["product"], i["g"]) for i in r["ingredients"] if "min" not in i]
    var = [i for i in r["ingredients"] if "min" in i]
    base = macros_of(fixed, products)
    # wiersze: dla każdego makro m  ->  sqrt(w)/t * (base_m + Σ a_mi x_i - t_m)
    rows = []
    for m in MACROS:
        t = max(target[m], 1e-6)
        k = math.sqrt(WEIGHTS[m]) / t
        rows.append(([k * products[i["product"]][m] / 100 for i in var], k * (t - base[m])))
    for j, i in enumerate(var):  # regularyzacja
        s = max(i["g"], i["max"] / 2, 1)
        coef = [0.0] * len(var)
        coef[j] = math.sqrt(reg) / s
        rows.append((coef, math.sqrt(reg) / s * i["g"]))
    x = [float(i["g"]) for i in var]
    lo = [i["min"] for i in var]
    hi = [i["max"] for i in var]
    for _ in range(300):  # projected coordinate descent
        for j in range(len(var)):
            num = den = 0.0
            for a, b in rows:
                rest = b - sum(a[k] * x[k] for k in range(len(var)) if k != j)
                num += a[j] * rest
                den += a[j] * a[j]
            if den > 0:
                x[j] = min(hi[j], max(lo[j], num / den))
    out = list(fixed)
    for i, xi in zip(var, x):
        step = i.get("step", ROUND_G)
        g = round(xi / step) * step
        g = min(i["max"], max(i["min"], g))
        out.append((i["product"], g))
    # zachowaj kolejność z przepisu
    order = {i["product"]: n for n, i in enumerate(r["ingredients"])}
    return sorted(out, key=lambda t: order[t[0]])


def day_target(settings, training):
    t = dict(settings["target"])
    if training:
        extra = settings["training_extra_kcal"]
        t["kcal"] += extra
        m = settings["training_extra_from"]
        t[m] += extra / (9 if m == "f" else 4)
    return t


def meal_target(day_t, n_meals):
    return {m: v / n_meals for m, v in day_t.items()}


# ---------------------------------------------------------------- sesja
def plan_session(settings, session, recipes, products):
    """session = {days: [{name, training, meals: {slot: True/False}}], prep: {slot: recipe_id}}
    Zwraca porcje per dzień/slot (tylko posiłki z prepu)."""
    portions = []
    for d in session["days"]:
        active = [s for s, on in d["meals"].items() if on]
        mt = meal_target(day_target(settings, d["training"]), len(active))
        for slot in active:
            rid = session["prep"].get(slot)
            if rid:
                items = scale_recipe(recipes[rid], products, mt)
                portions.append({"day": d["name"], "slot": slot, "recipe": rid,
                                 "items": items, "macros": macros_of(items, products), "target": mt})
    return portions


def best_packs(need, packs):
    """Najmniejsza nadwyżka, potem najmniej opakowań."""
    best = None
    for counts in itertools.product(range(0, 8), repeat=len(packs)):
        tot = sum(c * p for c, p in zip(counts, packs))
        if tot < need or sum(counts) == 0:
            continue
        key = (tot - need, sum(counts))
        if best is None or key < best[0]:
            best = (key, counts, tot)
    return best[1], best[2]


def shopping_list(portions, products, cats):
    need = {}
    for por in portions:
        for pid, g in por["items"]:
            need[pid] = need.get(pid, 0) + g
    buy, check = {}, []
    for pid, g in need.items():
        if g <= 0:
            continue
        p = products[pid]
        if p.get("staple"):
            check.append((p["name"], g))
            continue
        if p["pack"]:
            counts, tot = best_packs(g, p["pack"])
            label = " + ".join(f"{c}× {s} g" for c, s in zip(counts, p["pack"]) if c)
        elif p.get("piece_g"):
            n = math.ceil(g / p["piece_g"] - 0.15)  # tolerancja: 1,1 szt -> 1 szt
            n = max(n, 1)
            label = f"{n} szt (~{n * p['piece_g']} g)"
        else:
            label = f"{math.ceil(g / 50) * 50} g (na wagę)"
        buy.setdefault(p["cat"], []).append((p["name"], g, label))
    return [(c, buy[c]) for c in cats if c in buy], check


def schedule_session(recipe_ids, recipes, burners=4):
    """Wspólny plan sesji: 1 osoba (ręce) + N palników.
    Kroki aktywne zajmują ręce, pasywne tylko palnik (ręce na 1 min startu).
    Priorytet: najdłuższa ścieżka do końca przepisu (critical path)."""
    tasks = []
    for rid in recipe_ids:
        steps = recipes[rid]["steps"]
        for i, s in enumerate(steps, 1):
            deps = s.get("after", [i - 1] if i > 1 else [])
            tasks.append({"key": (rid, i), "rid": rid, "text": s["text"], "dur": s["min"],
                          "passive": s.get("passive", False), "burner": s.get("burner", False),
                          "deps": [(rid, d) for d in deps]})
    by = {t["key"]: t for t in tasks}
    # critical path od końca
    def tail(t, memo={}):
        if t["key"] in memo:
            return memo[t["key"]]
        nxt = [u for u in tasks if t["key"] in u["deps"]]
        memo[t["key"]] = t["dur"] + max((tail(u) for u in nxt), default=0)
        return memo[t["key"]]
    for t in tasks:
        t["prio"] = tail(t)
    time, hands_free, running, done, plan = 0, 0, [], set(), []
    pending = list(tasks)
    while pending or running:
        for t in [t for t in running if t["end"] <= time]:  # zakończ gotowe
            running.remove(t)
            done.add(t["key"])
        if not pending and not running:
            break
        if hands_free <= time:
            used = sum(1 for t in running if t["burner"])
            ready = [t for t in pending if all(d in done for d in t["deps"])
                     and not (t["burner"] and used >= burners)]
            if ready:
                t = max(ready, key=lambda t: t["prio"])
                t["start"], t["end"] = time, time + t["dur"]
                hands_free = time + (1 if t["passive"] else t["dur"])
                running.append(t)
                pending.remove(t)
                plan.append(t)
                continue
        events = [t["end"] for t in running if t["end"] > time] + ([hands_free] if hands_free > time else [])
        if not events:
            raise RuntimeError("zakleszczenie w planie sesji (sprawdź pola 'after')")
        time = min(events)
    total = max(t["end"] for t in plan)
    seq = sum(t["dur"] for t in tasks)
    return plan, total, seq


# ---------------------------------------------------------------- CLI
SETTINGS = {
    # przykładowe cele: wpiszesz swoje w aplikacji
    "target": {"kcal": 2500, "p": 150, "f": 75, "c": 305},
    "training_extra_kcal": 250,
    "training_extra_from": "c",
}


def fmt(m):
    return f"{m['kcal']:.0f} kcal  B {m['p']:.0f}  T {m['f']:.0f}  W {m['c']:.0f}"


def err_pct(m, t):
    return {k: 100 * (m[k] - t[k]) / t[k] for k in MACROS}


def cmd_validate(products, cats, recipes):
    bad = 0
    for rid, r in recipes.items():
        errs = validate_recipe(r, products)
        hard = [e for e in errs if not e.startswith("uwaga")]
        bad += bool(hard)
        if errs:
            print(f"{rid}: " + "; ".join(errs))
    print(f"\n{len(recipes)} przepisów, {len(products)} produktów, z błędami: {bad}")
    return bad


def cmd_report(products, cats, recipes):
    print("Błąd względem celu posiłku [%] (kcal / B / T / W) dla dnia 2500 kcal podzielonego na 3, 4 i 5 posiłków\n")
    for rid, r in recipes.items():
        cells = []
        for n in (3, 4, 5):
            t = meal_target(SETTINGS["target"], n)
            m = macros_of(scale_recipe(r, products, t), products)
            e = err_pct(m, t)
            cells.append("/".join(f"{e[k]:+3.0f}" for k in MACROS))
        print(f"{rid:28} " + "   ".join(cells))


def cmd_demo(products, cats, recipes):
    days = ["Pon", "Wt", "Śr", "Czw"]
    session = {
        "days": [{"name": d, "training": d in ("Wt", "Czw"),
                  "meals": {"śniadanie": d != "Śr", "obiad": True, "kolacja": True, "przekąska": True}}
                 for d in days],
        "prep": {"obiad": "chili-con-carne", "kolacja": "kurczak-curry-ryz"},
    }
    print(f"Cel dnia: {fmt(SETTINGS['target'])}  (+{SETTINGS['training_extra_kcal']} kcal w dni treningowe: Wt, Czw)")
    print("Posiłki: śniadanie (oprócz Śr), obiad i kolacja z prepu, przekąska na bieżąco\n")
    portions = plan_session(SETTINGS, session, recipes, products)
    for por in portions:
        e = err_pct(por["macros"], por["target"])
        main = ", ".join(f"{products[p]['name'].split(' (')[0]} {g:g} g" for p, g in por["items"]
                         if any(i["product"] == p and "min" in i for i in recipes[por["recipe"]]["ingredients"]))
        print(f"{por['day']:4} {por['slot']:8} {fmt(por['macros'])}   "
              f"(błąd kcal {e['kcal']:+.0f}%, B {e['p']:+.0f}%)   {main}")
    # udział w garnku dla pudełek
    print("\nPodział garnka (część partii na pudełko):")
    for slot, rid in session["prep"].items():
        ps = [p for p in portions if p["slot"] == slot]
        tot = sum(sum(g for _, g in p["items"]) for p in ps)
        print(f"  {recipes[rid]['name']}: " + ", ".join(
            f"{p['day']} {100 * sum(g for _, g in p['items']) / tot:.0f}%" for p in ps))
    groups, check = shopping_list(portions, products, cats)
    print("\nLISTA ZAKUPÓW (Biedronka)")
    cat_names = {c["id"]: c["name"] for c in json.loads((ROOT / "data/products.json").read_text())["categories"]}
    for cat, items in groups:
        print(f"  [{cat_names[cat]}]")
        for name, g, label in items:
            print(f"    □ {name:42} potrzeba {g:5.0f} g  ->  {label}")
    print("  [sprawdź, czy masz]")
    for name, g in check:
        print(f"    ? {name} ({g:.0f} g)")
    plan, total, seq = schedule_session(list(session["prep"].values()), recipes)
    print(f"\nWSPÓLNY PLAN SESJI: {total} min (osobno po kolei: {seq} min)")
    for t in plan:
        kind = "⏲" if t["passive"] else "✋"
        print(f"  {t['start']:3}-{t['end']:<3} {kind} [{recipes[t['rid']]['name'][:18]}] {t['text'][:70]}")


if __name__ == "__main__":
    products, cats, recipes = load()
    cmd = sys.argv[1] if len(sys.argv) > 1 else "validate"
    sys.exit({"validate": cmd_validate, "report": cmd_report, "demo": cmd_demo}[cmd](products, cats, recipes) or 0)
