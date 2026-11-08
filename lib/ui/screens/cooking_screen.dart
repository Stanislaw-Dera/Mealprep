import 'package:flutter/material.dart';

import '../../logic/cooking.dart';
import '../../logic/models.dart';
import '../app_scope.dart';
import '../widgets/session_view.dart';
import 'cook_recipe_screen.dart';

/// Zakładka „Gotowanie": dania wybranej sesji z łącznymi ilościami
/// składników i wejściem w gotowanie krok po kroku.
class CookingScreen extends StatelessWidget {
  const CookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SessionView(
      title: 'Gotowanie',
      emptyText:
          'Zaplanuj sesję w zakładce Plan, a tu pojawi się, co ugotować.',
      builder: (context, data) {
        final catalog = AppScope.of(context).catalog;
        // Każde danie raz, w kolejności posiłków w sesji.
        final recipeIds = <String>{for (final p in data.portions) p.recipeId};
        final totalMin = recipeIds.fold(
          0,
          (s, id) => s + catalog.recipes[id]!.timeMin,
        );
        return [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Suma do ugotowania: ${recipeIds.length} '
              '${recipeIds.length == 1 ? 'danie' : 'dania'}, '
              'razem ok. $totalMin min, jeśli robisz je po kolei.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          for (final id in recipeIds)
            _RecipeCard(
              recipe: catalog.recipes[id]!,
              totals: recipeTotals(data.portions, id),
              boxes: boxesFor(data.portions, id),
            ),
        ];
      },
    );
  }
}

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({
    required this.recipe,
    required this.totals,
    required this.boxes,
  });

  final Recipe recipe;
  final List<Amount> totals;
  final List<Box> boxes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final products = AppScope.of(context).catalog.products;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(recipe.name, style: theme.textTheme.titleMedium),
            Text(
              '${boxes.length} ${boxesWord(boxes.length)} · '
              'ok. ${recipe.timeMin} min · ${recipe.equipment.join(', ')}',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            for (final a in totals)
              if (a.g > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1),
                  child: Row(
                    children: [
                      Expanded(child: Text(products[a.productId]!.name)),
                      Text(
                        '${formatGrams(a.g)} g',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => CookRecipeScreen(
                    recipe: recipe,
                    totals: totals,
                    boxes: boxes,
                  ),
                ),
              ),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Gotuj krok po kroku'),
            ),
          ],
        ),
      ),
    );
  }
}
