"""Zapisuje dokładne wyniki prototypu do test/fixtures/proto_expected.json.

Testy w Darcie (test/logic_parity_test.dart) liczą to samo i porównują
z tym plikiem. Po zmianie logiki w prototypie albo danych uruchom:

  python3 tools/export_test_fixture.py
"""
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import mealprep_proto as mp  # noqa: E402

OUT = mp.ROOT / "test/fixtures/proto_expected.json"

# Ta sama sesja co w `mealprep_proto.py demo`.
DAYS = ["Pon", "Wt", "Śr", "Czw"]
SESSION = {
    "days": [{"name": d, "training": d in ("Wt", "Czw"),
              "meals": {"śniadanie": d != "Śr", "obiad": True, "kolacja": True, "przekąska": True}}
             for d in DAYS],
    "prep": {"obiad": "chili-con-carne", "kolacja": "kurczak-curry-ryz"},
}


# Celowo zepsute przepisy, żeby przetestować komunikaty walidacji.
_OK_STEP = {"text": "Gotuj", "min": 5}
BAD_RECIPES = {
    "brak-pol": {"format": "mealprep/1", "id": "x", "name": "X"},
    "zly-format": {"format": "mealprep/2", "id": "x", "name": "X", "meal_types": ["obiad", "deser"],
                   "prep": True, "time_min": 10,
                   "ingredients": [{"product": "nie-ma-takiego", "g": 10},
                                   {"product": "piers-kurczaka", "g": 300, "min": 50, "max": 200}],
                   "steps": [{"text": "a"}, {"text": "b", "min": 3, "after": [2, 5]}]},
    "bez-skalowania": {"format": "mealprep/1", "id": "x", "name": "X", "meal_types": ["obiad"],
                       "prep": False, "time_min": 10,
                       "ingredients": [{"product": "ryz-bialy", "g": 70}], "steps": [_OK_STEP]},
    "tylko-wegle": {"format": "mealprep/1", "id": "x", "name": "X", "meal_types": ["obiad"],
                    "prep": False, "time_min": 10,
                    "ingredients": [{"product": "ryz-bialy", "g": 70, "min": 20, "max": 160}],
                    "steps": [_OK_STEP]},
}


def items_json(items):
    return [[pid, g] for pid, g in items]


def main():
    products, cats, recipes = mp.load()

    validation = {rid: mp.validate_recipe(r, products) for rid, r in recipes.items()}
    bad_validation = {k: {"recipe": r, "errors": mp.validate_recipe(r, products)}
                      for k, r in BAD_RECIPES.items()}

    # Solver: każdy przepis dla dnia podzielonego na 3, 4 i 5 posiłków (jak `report`).
    scaling = {}
    for rid, r in recipes.items():
        scaling[rid] = {}
        for n in (3, 4, 5):
            t = mp.meal_target(mp.SETTINGS["target"], n)
            scaling[rid][str(n)] = items_json(mp.scale_recipe(r, products, t))

    portions = mp.plan_session(mp.SETTINGS, SESSION, recipes, products)
    groups, check = mp.shopping_list(portions, products, cats)
    plan, total, seq = mp.schedule_session(list(SESSION["prep"].values()), recipes)

    out = {
        "settings": mp.SETTINGS,
        "session": SESSION,
        "validation": validation,
        "bad_validation": bad_validation,
        "scaling": scaling,
        "portions": [{"day": p["day"], "slot": p["slot"], "recipe": p["recipe"],
                      "items": items_json(p["items"]), "macros": p["macros"], "target": p["target"]}
                     for p in portions],
        "shopping": {
            "groups": [{"cat": c, "items": [[name, g, label] for name, g, label in items]}
                       for c, items in groups],
            "check": [[name, g] for name, g in check],
        },
        "schedule": {
            "plan": [[t["rid"], t["key"][1], t["start"], t["end"]] for t in plan],
            "total": total,
            "seq": seq,
        },
    }
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(out, ensure_ascii=False, indent=1), encoding="utf-8")
    print(f"zapisano {OUT.relative_to(mp.ROOT)}")


if __name__ == "__main__":
    main()
