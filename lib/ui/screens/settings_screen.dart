import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../logic/models.dart';
import '../../logic/scaling.dart';
import '../app_scope.dart';

/// Zakładka „Ustawienia": cele makro, dodatek na dzień treningowy
/// i lista posiłków w dniu.
///
/// Zmiany trzymamy w polach ekranu i zapisujemy do bazy dopiero
/// przyciskiem „Zapisz".
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

/// Edytowany wiersz posiłku. [key] jest potrzebny do przeciągania.
class _SlotEdit {
  _SlotEdit(this.key, String name, this.prep)
    : name = TextEditingController(text: name);
  final int key;
  final TextEditingController name;
  bool prep;
}

/// Liczba z pola tekstowego; przyjmuje przecinek i kropkę.
double? parseNumber(String s) => double.tryParse(s.trim().replaceAll(',', '.'));

String _fmtNumber(double v) => v == v.roundToDouble()
    ? v.toInt().toString()
    : v.toString().replaceAll('.', ',');

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _kcal = TextEditingController();
  final _p = TextEditingController();
  final _f = TextEditingController();
  final _c = TextEditingController();
  final _extra = TextEditingController();
  Macro _extraFrom = Macro.c;
  final _slots = <_SlotEdit>[];
  int _nextKey = 0;

  bool _loading = true;
  bool _dirty = false;
  bool _saving = false;

  List<TextEditingController> get _numberFields => [_kcal, _p, _f, _c, _extra];

  @override
  void initState() {
    super.initState();
    for (final c in _numberFields) {
      c.addListener(_changed);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loading) _load();
  }

  Future<void> _load() async {
    final db = AppScope.of(context).db;
    final s = await db.loadSettings();
    final slots = await db.loadMealSlots();
    if (!mounted) return;
    _fill(s, slots);
  }

  /// Wpisuje wartości do pól (przy starcie i przy „Cofnij zmiany").
  void _fill(Settings s, List<MealSlot> slots) {
    _kcal.text = _fmtNumber(s.target.kcal);
    _p.text = _fmtNumber(s.target.p);
    _f.text = _fmtNumber(s.target.f);
    _c.text = _fmtNumber(s.target.c);
    _extra.text = _fmtNumber(s.trainingExtraKcal);
    for (final e in _slots) {
      _disposeLater(e.name);
    }
    _slots
      ..clear()
      ..addAll([for (final m in slots) _newSlot(m.name, m.prep)]);
    setState(() {
      _extraFrom = s.trainingExtraFrom;
      _loading = false;
      _dirty = false;
    });
  }

  _SlotEdit _newSlot(String name, bool prep) =>
      _SlotEdit(_nextKey++, name, prep)..name.addListener(_changed);

  /// Pole tekstowe jest jeszcze na ekranie w tej klatce, więc zwalniamy
  /// kontroler dopiero po jej narysowaniu.
  void _disposeLater(TextEditingController c) =>
      WidgetsBinding.instance.addPostFrameCallback((_) => c.dispose());

  void _changed() {
    if (_loading) return;
    setState(() => _dirty = true);
  }

  @override
  void dispose() {
    for (final c in _numberFields) {
      c.dispose();
    }
    for (final e in _slots) {
      e.name.dispose();
    }
    super.dispose();
  }

  /// Aktualne ustawienia z pól albo `null`, jeśli któreś pole jest błędne.
  Settings? _current() {
    final kcal = parseNumber(_kcal.text);
    final p = parseNumber(_p.text);
    final f = parseNumber(_f.text);
    final c = parseNumber(_c.text);
    final extra = parseNumber(_extra.text);
    if ([kcal, p, f, c, extra].contains(null)) return null;
    return Settings(
      target: Macros(kcal: kcal!, p: p!, f: f!, c: c!),
      trainingExtraKcal: extra!,
      trainingExtraFrom: _extraFrom,
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final s = _current()!;
    final slots = [
      for (final e in _slots) MealSlot(name: e.name.text.trim(), prep: e.prep),
    ];
    setState(() => _saving = true);
    final db = AppScope.of(context).db;
    await db.saveSettings(s);
    await db.saveMealSlots(slots);
    if (!mounted) return;
    setState(() {
      _saving = false;
      _dirty = false;
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Zapisano ustawienia')));
  }

  Future<void> _revert() async => _load();

  // ------------------------------------------------------------ widok

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Ustawienia')),
      body: Form(
        key: _formKey,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                _sectionTitle(theme, 'Cel na zwykły dzień'),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _numberField(_kcal, 'Kalorie', 'kcal', min: 1),
                    _numberField(_p, 'Białko (B)', 'g'),
                    _numberField(_f, 'Tłuszcz (T)', 'g'),
                    _numberField(_c, 'Węglowodany (W)', 'g'),
                  ],
                ),
                const SizedBox(height: 8),
                _macroCheck(theme),
                const SizedBox(height: 24),
                _sectionTitle(theme, 'Dzień treningowy'),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _numberField(_extra, 'Dodatkowo', 'kcal'),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('z czego', style: theme.textTheme.labelMedium),
                        const SizedBox(height: 4),
                        SegmentedButton<Macro>(
                          segments: const [
                            ButtonSegment(value: Macro.c, label: Text('W')),
                            ButtonSegment(value: Macro.p, label: Text('B')),
                            ButtonSegment(value: Macro.f, label: Text('T')),
                          ],
                          selected: {_extraFrom},
                          onSelectionChanged: (v) => setState(() {
                            _extraFrom = v.first;
                            _dirty = true;
                          }),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _sectionTitle(theme, 'Posiłki w dniu'),
                Text(
                  'Kolejność jak w ciągu dnia (przeciągnij za uchwyt). '
                  '„Z prepu" gotujesz w sesji do pudełek, resztę robisz na bieżąco. '
                  'Posiłek na konkretny dzień wyłączysz potem w planie.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                _slotList(),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => setState(() {
                      _slots.add(_newSlot('', false));
                      _dirty = true;
                    }),
                    icon: const Icon(Icons.add),
                    label: const Text('Dodaj posiłek'),
                  ),
                ),
                const SizedBox(height: 24),
                _sectionTitle(theme, 'Podgląd celu na posiłek'),
                _preview(theme),
                const SizedBox(height: 24),
                // Wrap zamiast Row: na wąskim telefonie przyciski
                // przechodzą do nowej linii zamiast wychodzić poza ekran.
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: _dirty && !_saving ? _save : null,
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Zapisz'),
                    ),
                    TextButton(
                      onPressed: _dirty && !_saving ? _revert : null,
                      child: const Text('Cofnij zmiany'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(ThemeData theme, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(text, style: theme.textTheme.titleMedium),
  );

  Widget _numberField(
    TextEditingController c,
    String label,
    String unit, {
    double min = 0,
  }) {
    return SizedBox(
      width: 150,
      child: TextFormField(
        controller: c,
        decoration: InputDecoration(
          labelText: label,
          suffixText: unit,
          border: const OutlineInputBorder(),
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
        ],
        validator: (v) {
          final x = parseNumber(v ?? '');
          if (x == null) return 'Wpisz liczbę';
          if (x < min) return min > 0 ? 'Musi być > 0' : 'Nie mniej niż 0';
          return null;
        },
      ),
    );
  }

  /// Czy kcal zgadzają się z makro (4·B + 9·T + 4·W).
  Widget _macroCheck(ThemeData theme) {
    final s = _current();
    if (s == null) return const SizedBox.shrink();
    final t = s.target;
    final fromMacros = 4 * t.p + 9 * t.f + 4 * t.c;
    final diff = t.kcal > 0 ? (fromMacros - t.kcal) / t.kcal : 0.0;
    final ok = diff.abs() <= 0.05;
    final pct = (diff * 100).round();
    return Row(
      children: [
        Icon(
          ok ? Icons.check_circle_outline : Icons.warning_amber_rounded,
          size: 18,
          color: ok ? theme.colorScheme.primary : theme.colorScheme.error,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Z makro wychodzi ${fromMacros.round()} kcal '
            '(4·B + 9·T + 4·W), ${pct >= 0 ? '+' : ''}$pct% względem celu'
            '${ok ? '' : '. Popraw makro albo kalorie'}',
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  Widget _slotList() {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: _slots.length,
      onReorderItem: (from, to) => setState(() {
        _slots.insert(to, _slots.removeAt(from));
        _dirty = true;
      }),
      itemBuilder: (context, i) {
        final e = _slots[i];
        return Padding(
          key: ValueKey(e.key),
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              ReorderableDragStartListener(
                index: i,
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.drag_indicator),
                ),
              ),
              Expanded(
                child: TextFormField(
                  controller: e.name,
                  decoration: InputDecoration(
                    labelText: 'Posiłek ${i + 1}',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (v) => _validateSlotName(e, v ?? ''),
                ),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('z prepu'),
                selected: e.prep,
                onSelected: (v) => setState(() {
                  e.prep = v;
                  _dirty = true;
                }),
              ),
              IconButton(
                tooltip: 'Usuń',
                onPressed: _slots.length > 1
                    ? () => setState(() {
                        _disposeLater(_slots.removeAt(i).name);
                        _dirty = true;
                      })
                    : null,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        );
      },
    );
  }

  String? _validateSlotName(_SlotEdit e, String v) {
    final name = v.trim().toLowerCase();
    if (name.isEmpty) return 'Podaj nazwę';
    final same = _slots.where((o) => o.name.text.trim().toLowerCase() == name);
    if (same.length > 1) return 'Nazwa się powtarza';
    return null;
  }

  /// Cel jednego posiłku, gdy jedzą się wszystkie posiłki z listy.
  Widget _preview(ThemeData theme) {
    final s = _current();
    final n = _slots.length;
    if (s == null || n == 0) {
      return Text('Uzupełnij pola powyżej.', style: theme.textTheme.bodySmall);
    }
    String row(bool training) {
      final m = mealTarget(dayTarget(s, training: training), n);
      return '${m.kcal.round()} kcal · B ${m.p.round()} · '
          'T ${m.f.round()} · W ${m.c.round()}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Przy $n posiłkach dziennie, cel dzielony równo:',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        Text('Zwykły dzień: ${row(false)}'),
        Text('Dzień treningowy: ${row(true)}'),
      ],
    );
  }
}
