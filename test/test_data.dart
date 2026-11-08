// Wspólne dla testów: wczytanie bazy z dysku (bez Fluttera i assets).
import 'dart:convert';
import 'dart:io';

import 'package:mealprep/logic/models.dart';

Map<String, dynamic> readJson(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

/// Przepisy posortowane po nazwie pliku, jak w aplikacji i w prototypie.
List<Map<String, dynamic>> readRecipesJson() {
  final files =
      Directory('data/recipes')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  return [for (final f in files) readJson(f.path)];
}

Catalog loadCatalog() =>
    Catalog.fromJson(readJson('data/products.json'), readRecipesJson());
