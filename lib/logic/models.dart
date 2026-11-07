/// Modele danych: produkty, przepisy i makroskładniki.
///
/// Odpowiada funkcji `load()` z tools/mealprep_proto.py. Klasy są niemutowalne
/// (pola `final`), a dane czytamy z JSON-a przez konstruktory `fromJson`.
library;

/// Makroskładnik. Klucze (`kcal`, `p`, `f`, `c`) są takie same jak w JSON-ie.
enum Macro {
  kcal(weight: 3.0),
  p(weight: 2.0), // białko (B)
  f(weight: 1.0), // tłuszcz (T)
  c(weight: 1.0); // węglowodany (W)

  const Macro({required this.weight});

  /// Waga w funkcji błędu solvera (SPEC.md: kcal = 3, B = 2, T = 1, W = 1).
  final double weight;

  static Macro fromKey(String key) => Macro.values.byName(key);
}

/// Wartości kcal, B, T, W. Używane jako makro produktu (na 100 g),
/// posiłku albo cel.
class Macros {
  const Macros({
    required this.kcal,
    required this.p,
    required this.f,
    required this.c,
  });

  const Macros.zero() : this(kcal: 0, p: 0, f: 0, c: 0);

  factory Macros.fromJson(Map<String, dynamic> j) => Macros(
    kcal: (j['kcal'] as num).toDouble(),
    p: (j['p'] as num).toDouble(),
    f: (j['f'] as num).toDouble(),
    c: (j['c'] as num).toDouble(),
  );

  final double kcal;
  final double p;
  final double f;
  final double c;

  double operator [](Macro m) => switch (m) {
    Macro.kcal => kcal,
    Macro.p => p,
    Macro.f => f,
    Macro.c => c,
  };

  /// Kopia z jedną wartością zmienioną.
  Macros withValue(Macro m, double v) => Macros(
    kcal: m == Macro.kcal ? v : kcal,
    p: m == Macro.p ? v : p,
    f: m == Macro.f ? v : f,
    c: m == Macro.c ? v : c,
  );

  Macros operator /(double d) =>
      Macros(kcal: kcal / d, p: p / d, f: f / d, c: c / d);

  Map<String, double> toJson() => {'kcal': kcal, 'p': p, 'f': f, 'c': c};

  @override
  String toString() =>
      '${kcal.toStringAsFixed(0)} kcal  B ${p.toStringAsFixed(0)}  '
      'T ${f.toStringAsFixed(0)}  W ${c.toStringAsFixed(0)}';
}

/// Dział sklepu (kolejność w products.json = kolejność przejścia przez Biedronkę).
class Category {
  const Category({required this.id, required this.name});

  factory Category.fromJson(Map<String, dynamic> j) =>
      Category(id: j['id'] as String, name: j['name'] as String);

  final String id;
  final String name;
}

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.per100g,
    this.packs = const [],
    this.pieceG,
    this.staple = false,
  });

  factory Product.fromJson(Map<String, dynamic> j) => Product(
    id: j['id'] as String,
    name: j['name'] as String,
    category: j['cat'] as String,
    per100g: Macros.fromJson(j),
    packs: [for (final x in (j['pack'] as List? ?? [])) (x as num).toInt()],
    pieceG: (j['piece_g'] as num?)?.toInt(),
    staple: j['staple'] as bool? ?? false,
  );

  final String id;
  final String name;

  /// ID działu (`cat` w JSON-ie).
  final String category;

  /// Makro na 100 g.
  final Macros per100g;

  /// Dostępne wielkości opakowań w gramach (`pack`). Puste = na sztuki albo na wagę.
  final List<int> packs;

  /// Waga jednej sztuki (`piece_g`), np. papryka, jajko.
  final int? pieceG;

  /// Zwykle jest w domu (oliwa, przyprawy) → sekcja „sprawdź, czy masz".
  final bool staple;
}

class Ingredient {
  const Ingredient({
    required this.productId,
    required this.g,
    this.min,
    this.max,
    this.step,
    this.note,
  });

  factory Ingredient.fromJson(Map<String, dynamic> j) => Ingredient(
    productId: j['product'] as String,
    g: (j['g'] as num).toDouble(),
    min: (j['min'] as num?)?.toDouble(),
    max: (j['max'] as num?)?.toDouble(),
    step: (j['step'] as num?)?.toDouble(),
    note: j['note'] as String?,
  );

  final String productId;

  /// Gramy na 1 porcję w przepisie.
  final double g;

  /// Zakres skalowania. Gdy oba są podane, składnik jest skalowalny.
  final double? min;
  final double? max;

  /// Krok zaokrąglenia (domyślnie 5 g).
  final double? step;
  final String? note;

  bool get scalable => min != null && max != null;
}

class RecipeStep {
  const RecipeStep({
    required this.text,
    required this.minutes,
    this.passive = false,
    this.burner = false,
    this.after,
  });

  factory RecipeStep.fromJson(Map<String, dynamic> j) => RecipeStep(
    text: j['text'] as String,
    minutes: (j['min'] as num).toInt(),
    passive: j['passive'] as bool? ?? false,
    burner: j['burner'] as bool? ?? false,
    after: (j['after'] as List?)?.map((e) => (e as num).toInt()).toList(),
  );

  final String text;
  final int minutes;

  /// Nie zajmuje rąk (gotowanie, duszenie).
  final bool passive;

  /// Zajmuje palnik.
  final bool burner;

  /// Numery kroków (od 1), które muszą się skończyć wcześniej.
  /// `null` = domyślnie poprzedni krok.
  final List<int>? after;
}

class Recipe {
  const Recipe({
    required this.id,
    required this.name,
    required this.mealTypes,
    required this.prep,
    required this.timeMin,
    required this.ingredients,
    required this.steps,
    this.fridgeDays,
    this.equipment = const [],
    this.tags = const [],
    this.extraProducts = const [],
  });

  factory Recipe.fromJson(Map<String, dynamic> j) => Recipe(
    id: j['id'] as String,
    name: j['name'] as String,
    mealTypes: List<String>.from(j['meal_types'] as List),
    prep: j['prep'] as bool,
    timeMin: (j['time_min'] as num).toInt(),
    fridgeDays: (j['fridge_days'] as num?)?.toInt(),
    equipment: List<String>.from(j['equipment'] as List? ?? []),
    tags: List<String>.from(j['tags'] as List? ?? []),
    ingredients: [
      for (final i in j['ingredients'] as List)
        Ingredient.fromJson(i as Map<String, dynamic>),
    ],
    steps: [
      for (final s in j['steps'] as List)
        RecipeStep.fromJson(s as Map<String, dynamic>),
    ],
    extraProducts: [
      for (final p in j['products'] as List? ?? [])
        Product.fromJson(p as Map<String, dynamic>),
    ],
  );

  final String id;
  final String name;
  final List<String> mealTypes;
  final bool prep;
  final int timeMin;
  final int? fridgeDays;
  final List<String> equipment;
  final List<String> tags;
  final List<Ingredient> ingredients;
  final List<RecipeStep> steps;

  /// Produkty zdefiniowane w samym przepisie (pole `products`).
  final List<Product> extraProducts;
}

/// Cała baza: produkty, działy w kolejności sklepu i przepisy.
class Catalog {
  Catalog._(this.products, this.categories, this.recipes);

  /// [productsJson] to zawartość products.json, [recipesJson] to przepisy
  /// w kolejności nazw plików (jak `sorted(glob(...))` w prototypie).
  factory Catalog.fromJson(
    Map<String, dynamic> productsJson,
    List<Map<String, dynamic>> recipesJson,
  ) {
    final products = <String, Product>{
      for (final p in productsJson['products'] as List)
        (p as Map<String, dynamic>)['id'] as String: Product.fromJson(p),
    };
    final categories = [
      for (final c in productsJson['categories'] as List)
        Category.fromJson(c as Map<String, dynamic>),
    ];
    final recipes = <String, Recipe>{};
    for (final rj in recipesJson) {
      final r = Recipe.fromJson(rj);
      // Jak `setdefault`: produkt z bazy ma pierwszeństwo przed definicją w przepisie.
      for (final extra in r.extraProducts) {
        products.putIfAbsent(extra.id, () => extra);
      }
      recipes[r.id] = r;
    }
    return Catalog._(products, categories, recipes);
  }

  final Map<String, Product> products;
  final List<Category> categories;
  final Map<String, Recipe> recipes;
}

/// Gramatura jednego produktu w porcji albo na liście zakupów.
typedef Amount = ({String productId, double g});
