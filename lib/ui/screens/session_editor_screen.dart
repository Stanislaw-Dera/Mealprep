import 'package:flutter/material.dart';

import '../../logic/models.dart';
import '../../logic/scaling.dart';
import '../../logic/session.dart';
import '../../logic/session_plan.dart';
import '../app_scope.dart';
import 'recipe_picker_screen.dart';

/// Edytor sesji: dni, dania z prepu i wyliczone porcje.
///
/// Każda zmiana od razu trafia do bazy (bez przycisku „Zapisz"),
/// a porcje liczą się na nowo przy każdym przerysowaniu. Solver jest szybki,
/// więc nie trzeba niczego cache'ować.
class SessionEditorScreen extends StatefulWidget {
  const SessionEditorScreen({super.key, required this.initial});

  final SessionPlan initial;

  @override
  State<SessionEditorScreen> createState() => _SessionEditorScreenState();
}

const _maxDays = 7;

class _SessionEditorScreenState extends State<SessionEditorScreen> {
  late SessionPlan _plan = widget.initial;
  Settings? _settings;

  /// Kolejka zapisów, żeby szybkie kliknięcia zapisywały się po kolei.
  Future<void> _saving = Future.value();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_settings == null) {
      AppScope.of(context).db.loadSettings().then((s) {
        if (mounted) setState(() => _settings = s);
      });
    }
  }

  void _update(SessionPlan p) {
    setState(() => _plan = p);
    final db = AppScope.of(context).db;
    _saving = _saving.then((_) => db.saveSession(p));
  }

  Future<void> _pickFirstDay() async {
    final today = dateOnly(DateTime.now());
    final d = await showDatePicker(
      context: context,
      initialDate: _plan.firstDay,
      firstDate: today.subtract(const Duration(days: 365)),
      lastDate: today.add(const Duration(days: 365)),
      helpText: 'Pierwszy dzień sesji',
    );
    if (d != null) _update(_plan.copyWith(firstDay: dateOnly(d)));
  }

  Future<void> _pickRecipe(MealSlot slot) async {
    final picked = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => RecipePickerScreen(
          slotName: slot.name,
          target: mealTarget(
            dayTarget(_settings!, training: false),
            _plan.slots.length,
          ),
          currentId: _plan.recipes[slot.name],
          dayCount: _plan.days.length,
        ),
      ),
    );
    if (picked == null) return; // anulowano
    _update(_plan.withRecipe(slot.name, picked.isEmpty ? null : picked));
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Usunąć sesję?'),
        content: const Text('Tej operacji nie można cofnąć.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _saving;
    if (!mounted) return;
    await AppScope.of(context).db.deleteSession(_plan.id!);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final settings = _settings;
    return Scaffold(
      appBar: AppBar(
        title: Text('Sesja od ${dayLabel(_plan.firstDay)}'),
        actions: [
          IconButton(
            tooltip: 'Usuń sesję',
            onPressed: _plan.id == null ? null : _delete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: settings == null
          ? const Center(child: CircularProgressIndicator())
          : _body(context, settings),
    );
  }

  Widget _body(BuildContext context, Settings settings) {
    final theme = Theme.of(context);
    final catalog = AppScope.of(context).catalog;
    final portions = planSession(settings, _plan.toSession(), catalog);
    final byKey = {for (final p in portions) '${p.day}|${p.slot}': p};

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _title(theme, 'Dni'),
            _daysControls(theme),
            const SizedBox(height: 24),
            _title(theme, 'Dania z prepu'),
            ..._prepSlotTiles(theme, catalog),
            const SizedBox(height: 24),
            _title(theme, 'Porcje na każdy dzień'),
            _dayCards(theme, settings, catalog, byKey),
            if (portions.isNotEmpty) ...[
              const SizedBox(height: 24),
              _title(theme, 'Podział garnka na pudełka'),
              _potShares(theme, catalog, portions),
            ],
          ],
        ),
      ),
    );
  }

  Widget _title(ThemeData theme, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: theme.textTheme.titleMedium),
  );

  Widget _daysControls(ThemeData theme) {
    final n = _plan.days.length;
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        OutlinedButton.icon(
          onPressed: _pickFirstDay,
          icon: const Icon(Icons.event),
          label: Text('Od ${dayLabel(_plan.firstDay)}'),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Mniej dni',
              onPressed: n > 1
                  ? () => _update(_plan.withDayCount(n - 1))
                  : null,
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Text('$n ${n == 1 ? 'dzień' : 'dni'}'),
            IconButton(
              tooltip: 'Więcej dni',
              onPressed: n < _maxDays
                  ? () => _update(_plan.withDayCount(n + 1))
                  : null,
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
        Text('do ${dayLabel(_plan.lastDay)}', style: theme.textTheme.bodySmall),
      ],
    );
  }

  List<Widget> _prepSlotTiles(ThemeData theme, Catalog catalog) {
    final slots = _plan.prepSlots;
    if (slots.isEmpty) {
      return [
        const Text(
          'Ta sesja nie ma posiłków z prepu. Zaznacz je w Ustawieniach '
          'i utwórz nową sesję.',
        ),
      ];
    }
    return [
      for (final slot in slots)
        Builder(
          builder: (context) {
            final recipe = catalog.recipes[_plan.recipes[slot.name]];
            final warn = _fridgeWarning(recipe);
            return Card(
              child: ListTile(
                leading: const Icon(Icons.restaurant),
                title: Text(slot.name),
                subtitle: Text(
                  recipe == null
                      ? 'Wybierz danie'
                      : warn == null
                      ? recipe.name
                      : '${recipe.name}\n$warn',
                  style: warn == null && recipe != null
                      ? null
                      : TextStyle(
                          color: recipe == null
                              ? theme.colorScheme.primary
                              : theme.colorScheme.error,
                        ),
                ),
                isThreeLine: warn != null,
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _pickRecipe(slot),
              ),
            );
          },
        ),
    ];
  }

  String? _fridgeWarning(Recipe? r) {
    final fd = r?.fridgeDays;
    if (fd == null || _plan.days.length <= fd) return null;
    return 'Wytrzyma w lodówce $fd dni, a sesja ma ${_plan.days.length}';
  }

  Widget _dayCards(
    ThemeData theme,
    Settings settings,
    Catalog catalog,
    Map<String, Portion> byKey,
  ) {
    return LayoutBuilder(
      builder: (context, c) {
        const gap = 12.0;
        final cols = (c.maxWidth / 300).floor().clamp(1, 4);
        final width = (c.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var i = 0; i < _plan.days.length; i++)
              SizedBox(
                width: width,
                child: _dayCard(theme, settings, catalog, byKey, i),
              ),
          ],
        );
      },
    );
  }

  Widget _dayCard(
    ThemeData theme,
    Settings settings,
    Catalog catalog,
    Map<String, Portion> byKey,
    int i,
  ) {
    final day = _plan.days[i];
    final label = _plan.labelOf(i);
    final active = _plan.activeMeals(i);
    final perMeal = active == 0
        ? null
        : mealTarget(dayTarget(settings, training: day.training), active);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(label, style: theme.textTheme.titleSmall)),
                FilterChip(
                  avatar: const Icon(Icons.fitness_center, size: 16),
                  label: const Text('Trening'),
                  selected: day.training,
                  showCheckmark: false,
                  onSelected: (v) =>
                      _update(_plan.withDay(i, day.copyWith(training: v))),
                ),
              ],
            ),
            const SizedBox(height: 4),
            for (final slot in _plan.slots)
              _mealRow(theme, catalog, byKey, i, label, slot, perMeal),
          ],
        ),
      ),
    );
  }

  Widget _mealRow(
    ThemeData theme,
    Catalog catalog,
    Map<String, Portion> byKey,
    int i,
    String label,
    MealSlot slot,
    Macros? perMeal,
  ) {
    final day = _plan.days[i];
    final on = !day.off.contains(slot.name);
    final portion = byKey['$label|${slot.name}'];
    final small = theme.textTheme.bodySmall;
    final muted = small?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    final details = <Widget>[];
    if (!on) {
      details.add(Text('nie jem', style: muted));
    } else if (portion != null) {
      details.add(Text(_macroLine(portion.macros), style: small));
      details.add(Text(_mainIngredients(portion, catalog), style: muted));
    } else if (slot.prep) {
      details.add(Text('wybierz danie powyżej', style: muted));
    } else if (perMeal != null) {
      details.add(Text('na bieżąco: ${_macroLine(perMeal)}', style: muted));
    }

    return InkWell(
      onTap: () {
        final off = {...day.off};
        on ? off.add(slot.name) : off.remove(slot.name);
        _update(_plan.withDay(i, day.copyWith(off: off)));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              on ? Icons.check_box : Icons.check_box_outline_blank,
              size: 20,
              color: on
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    slot.name,
                    style: on
                        ? null
                        : TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  ...details,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _potShares(ThemeData theme, Catalog catalog, List<Portion> portions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Jaką część ugotowanego garnka nałożyć do pudełka na dany dzień.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        for (final MapEntry(key: slot, value: rid)
            in _plan.toSession().prep.entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              '${catalog.recipes[rid]!.name}: ${potShares(portions, slot).entries.map((e) => '${e.key} ${(e.value * 100).round()}%').join(' · ')}',
            ),
          ),
      ],
    );
  }
}

String _macroLine(Macros m) =>
    '${m.kcal.round()} kcal · B ${m.p.round()} · T ${m.f.round()} · W ${m.c.round()}';

/// Gramatury składników skalowalnych, np. „Pierś z kurczaka 115 g · Ryż biały 85 g".
String _mainIngredients(Portion p, Catalog catalog) {
  final recipe = catalog.recipes[p.recipeId]!;
  final scalable = {
    for (final i in recipe.ingredients)
      if (i.scalable) i.productId,
  };
  return [
    for (final a in p.items)
      if (scalable.contains(a.productId) && a.g > 0)
        '${catalog.products[a.productId]!.name.split(' (').first} ${_g(a.g)} g',
  ].join(' · ');
}

String _g(double g) =>
    g == g.roundToDouble() ? g.toInt().toString() : g.toStringAsFixed(1);
