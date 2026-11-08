import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../logic/cooking.dart';
import '../../logic/models.dart';
import '../app_scope.dart';

/// Gotowanie jednego dania: składniki na całą partię, kroki po kolei
/// z minutnikami i podział ugotowanej potrawy na pudełka.
///
/// Minutniki działają niezależnie od tego, który krok oglądasz: możesz
/// nastawić gotowanie ryżu i przejść do krojenia.
class CookRecipeScreen extends StatefulWidget {
  const CookRecipeScreen({
    super.key,
    required this.recipe,
    required this.totals,
    required this.boxes,
    this.clock = DateTime.now,
  });

  final Recipe recipe;
  final List<Amount> totals;
  final List<Box> boxes;

  /// Źródło aktualnego czasu (w testach można podać własne).
  final DateTime Function() clock;

  @override
  State<CookRecipeScreen> createState() => _CookRecipeScreenState();
}

enum _View { ingredients, steps, boxes }

class _CookRecipeScreenState extends State<CookRecipeScreen> {
  _View _view = _View.ingredients;
  int _step = 0;

  /// Odhaczone (odmierzone) składniki.
  final _measured = <String>{};

  /// Minutnik każdego kroku (numer kroku od 0).
  late final List<StepTimer> _timers = [
    for (final s in widget.recipe.steps)
      StepTimer(Duration(minutes: s.minutes)),
  ];

  /// Kroki, o których końcu już powiadomiliśmy.
  final _announced = <int>{};

  /// Tyka co sekundę, tylko gdy jakiś minutnik chodzi.
  Timer? _ticker;

  final _weight = TextEditingController();

  late final Map<String, double> _totalsMap = {
    for (final a in widget.totals) a.productId: a.g,
  };

  @override
  void dispose() {
    _ticker?.cancel();
    _weight.dispose();
    super.dispose();
  }

  // --------------------------------------------------------- minutniki

  void _updateTicker() {
    final anyRunning = _timers.any((t) => t.running);
    if (anyRunning && _ticker == null) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    } else if (!anyRunning) {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  void _tick() {
    final now = widget.clock();
    for (var i = 0; i < _timers.length; i++) {
      final t = _timers[i];
      if (t.running && t.finished(now)) {
        t.pause(now);
        if (_announced.add(i)) _announce(i);
      }
    }
    _updateTicker();
    setState(() {});
  }

  void _announce(int i) {
    SystemSound.play(SystemSoundType.alert);
    HapticFeedback.heavyImpact();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 10),
        content: Text('Minutnik: krok ${i + 1} gotowy'),
        action: SnackBarAction(
          label: 'Pokaż',
          onPressed: () => setState(() {
            _view = _View.steps;
            _step = i;
          }),
        ),
      ),
    );
  }

  void _startPause(int i) {
    final now = widget.clock();
    final t = _timers[i];
    setState(() => t.running ? t.pause(now) : t.start(now));
    _updateTicker();
  }

  void _reset(int i) {
    setState(() {
      _timers[i].reset();
      _announced.remove(i);
    });
    _updateTicker();
  }

  /// Czy wyjście z ekranu wyłączy działające minutniki (pytamy wtedy o zgodę).
  bool get _hasRunningTimers => _timers.any((t) => t.running);

  Future<void> _confirmLeave() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Minutniki dalej chodzą'),
        content: const Text(
          'Po wyjściu z tego ekranu minutniki się zatrzymają.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Zostań'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Wyjdź'),
          ),
        ],
      ),
    );
    if (leave == true && mounted) Navigator.of(context).pop();
  }

  // ------------------------------------------------------------- widok

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasRunningTimers,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(widget.recipe.name)),
        body: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: SegmentedButton<_View>(
                    segments: const [
                      ButtonSegment(
                        value: _View.ingredients,
                        icon: Icon(Icons.scale_outlined),
                        label: Text('Składniki'),
                      ),
                      ButtonSegment(
                        value: _View.steps,
                        icon: Icon(Icons.format_list_numbered),
                        label: Text('Kroki'),
                      ),
                      ButtonSegment(
                        value: _View.boxes,
                        icon: Icon(Icons.inventory_2_outlined),
                        label: Text('Pudełka'),
                      ),
                    ],
                    selected: {_view},
                    onSelectionChanged: (v) => setState(() => _view = v.first),
                  ),
                ),
                _runningTimersBar(),
                Expanded(
                  child: switch (_view) {
                    _View.ingredients => _ingredients(),
                    _View.steps => _steps(),
                    _View.boxes => _boxesView(),
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Minutniki z innych kroków niż oglądany: żeby nie zapomnieć o ryżu.
  Widget _runningTimersBar() {
    final now = widget.clock();
    final others = [
      for (var i = 0; i < _timers.length; i++)
        if ((_view != _View.steps || i != _step) &&
            (_timers[i].running || _announced.contains(i)))
          i,
    ];
    if (others.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          for (final i in others)
            ActionChip(
              avatar: Icon(
                _timers[i].finished(now)
                    ? Icons.alarm_on
                    : Icons.timer_outlined,
                size: 18,
              ),
              label: Text(
                'Krok ${i + 1} · ${_timers[i].finished(now) ? 'gotowe' : formatDuration(_timers[i].remaining(now))}',
              ),
              backgroundColor: _timers[i].finished(now)
                  ? theme.colorScheme.errorContainer
                  : null,
              onPressed: () => setState(() {
                _view = _View.steps;
                _step = i;
              }),
            ),
        ],
      ),
    );
  }

  Widget _ingredients() {
    final products = AppScope.of(context).catalog.products;
    final notes = {
      for (final i in widget.recipe.ingredients)
        if (i.note != null) i.productId: i.note!,
    };
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            'Na całą partię (${widget.boxes.length} ${boxesWord(widget.boxes.length)}). '
            'Ryż, kasza i makaron na sucho, mięso surowe.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        for (final a in widget.totals)
          if (a.g > 0)
            CheckboxListTile(
              value: _measured.contains(a.productId),
              onChanged: (v) => setState(
                () => v == true
                    ? _measured.add(a.productId)
                    : _measured.remove(a.productId),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(products[a.productId]!.name),
              subtitle: notes[a.productId] == null
                  ? null
                  : Text(notes[a.productId]!),
              secondary: Text(
                '${formatGrams(a.g)} g',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: () => setState(() => _view = _View.steps),
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Do kroków'),
          ),
        ),
      ],
    );
  }

  Widget _steps() {
    final theme = Theme.of(context);
    final steps = widget.recipe.steps;
    final s = steps[_step];
    final t = _timers[_step];
    final now = widget.clock();
    final last = _step == steps.length - 1;
    final segments = fillStepText(s.text, _totalsMap);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(
          'Krok ${_step + 1} z ${steps.length}',
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(value: (_step + 1) / steps.length),
        const SizedBox(height: 24),
        Text.rich(
          TextSpan(
            children: [
              for (final seg in segments)
                TextSpan(
                  text: seg.text,
                  style: seg.amount
                      ? TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        )
                      : null,
                ),
            ],
          ),
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            Chip(
              avatar: const Icon(Icons.schedule, size: 18),
              label: Text('${s.minutes} min'),
            ),
            if (s.passive)
              const Chip(
                avatar: Icon(Icons.pan_tool_alt_outlined, size: 18),
                label: Text('nie zajmuje rąk'),
              ),
            if (s.burner)
              const Chip(
                avatar: Icon(Icons.local_fire_department_outlined, size: 18),
                label: Text('palnik'),
              ),
          ],
        ),
        if (s.minutes > 0) ...[
          const SizedBox(height: 24),
          Card(
            color: t.finished(now) ? theme.colorScheme.errorContainer : null,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    t.finished(now)
                        ? 'Gotowe!'
                        : formatDuration(t.remaining(now)),
                    style: theme.textTheme.displayMedium?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FilledButton.icon(
                        onPressed: t.finished(now)
                            ? null
                            : () => _startPause(_step),
                        icon: Icon(t.running ? Icons.pause : Icons.play_arrow),
                        label: Text(
                          t.running
                              ? 'Pauza'
                              : t.started(now)
                              ? 'Wznów'
                              : 'Start',
                        ),
                      ),
                      const SizedBox(width: 12),
                      TextButton.icon(
                        onPressed: t.started(now) ? () => _reset(_step) : null,
                        icon: const Icon(Icons.replay),
                        label: const Text('Od nowa'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: _step > 0 ? () => setState(() => _step--) : null,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Wstecz'),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: () => setState(() {
                if (last) {
                  _view = _View.boxes;
                } else {
                  _step++;
                }
              }),
              icon: Icon(
                last ? Icons.inventory_2_outlined : Icons.arrow_forward,
              ),
              label: Text(last ? 'Do pudełek' : 'Dalej'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _boxesView() {
    final theme = Theme.of(context);
    final weight = double.tryParse(_weight.text.trim().replaceAll(',', '.'));
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(
          'Porcje różnią się między dniami, więc dziel garnek według procentów. '
          'Zważ całą ugotowaną potrawę (bez garnka), a pokażę gramy na każde pudełko.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: 260,
          child: TextField(
            controller: _weight,
            decoration: const InputDecoration(
              labelText: 'Waga ugotowanej potrawy',
              suffixText: 'g',
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: 12),
        for (final b in widget.boxes)
          ListTile(
            leading: const Icon(Icons.inventory_2_outlined),
            title: Text('${b.day} · ${b.slot}'),
            subtitle: Text('${(b.share * 100).round()}% garnka'),
            trailing: weight == null || weight <= 0
                ? null
                : Text(
                    '${(weight * b.share).round()} g',
                    style: theme.textTheme.titleLarge,
                  ),
          ),
      ],
    );
  }
}
