import 'package:flutter/material.dart';

import '../../logic/models.dart';
import '../../logic/scaling.dart';
import '../../logic/session_plan.dart';
import '../app_scope.dart';

/// Wybór dania z prepu dla posiłku.
///
/// Zwraca przez `Navigator.pop`: ID przepisu, pusty tekst = „bez dania",
/// `null` = anulowano (strzałka wstecz).
class RecipePickerScreen extends StatelessWidget {
  const RecipePickerScreen({
    super.key,
    required this.slotName,
    required this.target,
    required this.dayCount,
    this.currentId,
  });

  final String slotName;

  /// Cel posiłku w zwykły dzień: do niego liczymy dopasowanie.
  final Macros target;
  final int dayCount;
  final String? currentId;

  @override
  Widget build(BuildContext context) {
    final catalog = AppScope.of(context).catalog;
    final type = mealTypeForSlot(slotName);

    final fits = [
      for (final r in catalog.recipes.values)
        if (r.prep) _Fit.of(r, catalog, target),
    ];
    // Najpierw dania pasujące typem posiłku, w każdej grupie najlepsze trafienie w makro.
    final matching =
        fits.where((f) => f.recipe.mealTypes.contains(type)).toList()
          ..sort((a, b) => a.score.compareTo(b.score));
    final other = fits.where((f) => !f.recipe.mealTypes.contains(type)).toList()
      ..sort((a, b) => a.score.compareTo(b.score));

    final theme = Theme.of(context);
    Widget header(String t) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(t, style: theme.textTheme.titleSmall),
    );

    return Scaffold(
      appBar: AppBar(title: Text(slotName)),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              'Odchylenie od celu posiłku (${target.kcal.round()} kcal, '
              'B ${target.p.round()}) po dobraniu gramatur.',
              style: theme.textTheme.bodySmall,
            ),
          ),
          if (currentId != null)
            ListTile(
              leading: const Icon(Icons.clear),
              title: const Text('Bez dania'),
              onTap: () => Navigator.pop(context, ''),
            ),
          if (matching.isNotEmpty) header('Pasują do: $slotName'),
          for (final f in matching) _tile(context, f),
          if (other.isNotEmpty) header('Pozostałe dania do prepu'),
          for (final f in other) _tile(context, f),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, _Fit f) {
    final theme = Theme.of(context);
    final r = f.recipe;
    final fridgeBad = r.fridgeDays != null && dayCount > r.fridgeDays!;
    final bad = f.kcalErr.abs() > 10 || f.pErr.abs() > 10;
    return ListTile(
      title: Text(r.name),
      subtitle: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: '${r.timeMin} min · '),
            TextSpan(
              text: 'lodówka ${r.fridgeDays} dni',
              style: fridgeBad
                  ? TextStyle(color: theme.colorScheme.error)
                  : null,
            ),
            const TextSpan(text: ' · '),
            TextSpan(
              text: 'kcal ${_pct(f.kcalErr)}, B ${_pct(f.pErr)}',
              style: bad ? TextStyle(color: theme.colorScheme.error) : null,
            ),
          ],
        ),
      ),
      trailing: r.id == currentId
          ? Icon(Icons.check, color: theme.colorScheme.primary)
          : null,
      onTap: () => Navigator.pop(context, r.id),
    );
  }
}

String _pct(double v) {
  final r = v.round();
  return '${r > 0
      ? '+'
      : r < 0
      ? '−'
      : '±'}${r.abs()}%';
}

/// Jak dobrze przepis trafia w cel po przeskalowaniu.
class _Fit {
  _Fit(this.recipe, this.kcalErr, this.pErr);

  factory _Fit.of(Recipe r, Catalog catalog, Macros target) {
    final m = macrosOf(
      scaleRecipe(r, catalog.products, target),
      catalog.products,
    );
    double err(Macro x) =>
        target[x] == 0 ? 0 : 100 * (m[x] - target[x]) / target[x];
    return _Fit(r, err(Macro.kcal), err(Macro.p));
  }

  final Recipe recipe;
  final double kcalErr;
  final double pErr;

  /// Do sortowania: ważony błąd jak w solverze (kcal ×3, B ×2).
  double get score => 3 * kcalErr * kcalErr + 2 * pErr * pErr;
}
