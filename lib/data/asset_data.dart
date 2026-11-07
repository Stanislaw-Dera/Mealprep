import 'dart:convert';

import 'package:flutter/services.dart';

import '../logic/models.dart';

/// Surowe dane wbudowane w aplikację (folder `data/` zadeklarowany w pubspec.yaml).
///
/// Surowe mapy z JSON-a. [toCatalog] zamienia je na modele z lib/logic/.
class AssetData {
  AssetData({required this.products, required this.recipes});

  /// Zawartość data/products.json.
  final Map<String, dynamic> products;

  /// Wszystkie przepisy z data/recipes/*.json, posortowane po nazwie pliku.
  final List<Map<String, dynamic>> recipes;

  static const _productsPath = 'data/products.json';
  static const _recipesDir = 'data/recipes/';

  static Future<AssetData> load([AssetBundle? bundle]) async {
    final b = bundle ?? rootBundle;

    final products =
        jsonDecode(await b.loadString(_productsPath)) as Map<String, dynamic>;

    // Flutter nie pozwala "wylistować folderu" w assets, ale ma manifest
    // ze wszystkimi plikami. Wybieramy z niego pliki przepisów.
    final manifest = await AssetManifest.loadFromAssetBundle(b);
    final recipePaths =
        manifest
            .listAssets()
            .where((p) => p.startsWith(_recipesDir) && p.endsWith('.json'))
            .toList()
          ..sort();

    final recipes = <Map<String, dynamic>>[];
    for (final path in recipePaths) {
      recipes.add(jsonDecode(await b.loadString(path)) as Map<String, dynamic>);
    }

    return AssetData(products: products, recipes: recipes);
  }

  Catalog toCatalog() => Catalog.fromJson(products, recipes);
}
