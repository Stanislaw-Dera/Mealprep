/// Tryb gotowania: sumy składników na partię, podział na pudełka,
/// tekst kroków z wstawionymi gramaturami i minutnik.
library;

import 'models.dart';
import 'session.dart';

/// Łączne gramatury składników dania na całą sesję (wszystkie pudełka),
/// w kolejności z przepisu.
List<Amount> recipeTotals(List<Portion> portions, String recipeId) {
  final sums = <String, double>{};
  for (final p in portions.where((p) => p.recipeId == recipeId)) {
    for (final (:productId, :g) in p.items) {
      sums[productId] = (sums[productId] ?? 0) + g;
    }
  }
  return [for (final e in sums.entries) (productId: e.key, g: e.value)];
}

/// Jedno pudełko z garnka danego dania.
typedef Box = ({String day, String slot, double share, double rawG});

/// Pudełka danego dania i ich udział w garnku (suma udziałów = 1).
/// Udział liczymy z surowych gramatur porcji, jak `potShares`.
List<Box> boxesFor(List<Portion> portions, String recipeId) {
  final ps = portions.where((p) => p.recipeId == recipeId).toList();
  final tot = ps.fold(0.0, (s, p) => s + p.totalG);
  return [
    for (final p in ps)
      (day: p.day, slot: p.slot, share: p.totalG / tot, rawG: p.totalG),
  ];
}

/// Kawałek tekstu kroku. [amount] = wstawiona gramatura (do pogrubienia).
typedef StepSegment = ({String text, bool amount});

final _placeholder = RegExp(r'\{([a-z0-9-]+)\}');

/// Zamienia `{id-produktu}` na łączną ilość w sesji, np. „Ugotuj {ryz-bialy}
/// ryżu" → „Ugotuj " + „280 g" + „ ryżu". Nieznane ID zostają bez zmian.
List<StepSegment> fillStepText(String text, Map<String, double> totals) {
  final out = <StepSegment>[];
  var last = 0;
  for (final m in _placeholder.allMatches(text)) {
    final g = totals[m.group(1)];
    if (g == null) continue;
    if (m.start > last) {
      out.add((text: text.substring(last, m.start), amount: false));
    }
    out.add((text: '${formatGrams(g)} g', amount: true));
    last = m.end;
  }
  if (last < text.length) out.add((text: text.substring(last), amount: false));
  return out;
}

/// Gramy bez „,0"; ułamki z przecinkiem (np. „2,5").
String formatGrams(double g) => g == g.roundToDouble()
    ? g.toInt().toString()
    : g.toStringAsFixed(1).replaceAll('.', ',');

/// Minutnik kroku. Liczy czas z zegara ([now]), a nie z liczby „tyknięć",
/// więc się nie spóźnia, nawet gdy aplikacja była chwilę w tle.
class StepTimer {
  StepTimer(this.total);

  final Duration total;
  DateTime? _startedAt;
  Duration _elapsedBefore = Duration.zero;

  bool get running => _startedAt != null;

  Duration elapsed(DateTime now) =>
      _elapsedBefore +
      (_startedAt == null ? Duration.zero : now.difference(_startedAt!));

  /// Pozostały czas (nie mniej niż zero).
  Duration remaining(DateTime now) {
    final r = total - elapsed(now);
    return r.isNegative ? Duration.zero : r;
  }

  bool finished(DateTime now) => remaining(now) == Duration.zero;

  /// Czy minutnik jest „w użyciu" (wystartowany albo zapauzowany w trakcie).
  bool started(DateTime now) => running || elapsed(now) > Duration.zero;

  void start(DateTime now) {
    if (running || finished(now)) return;
    _startedAt = now;
  }

  void pause(DateTime now) {
    if (!running) return;
    _elapsedBefore = elapsed(now);
    _startedAt = null;
  }

  void reset() {
    _startedAt = null;
    _elapsedBefore = Duration.zero;
  }
}

/// „mm:ss", a od godziny „h:mm:ss".
String formatDuration(Duration d) {
  final s = d.inSeconds;
  final h = s ~/ 3600, m = (s % 3600) ~/ 60, sec = s % 60;
  String two(int v) => v.toString().padLeft(2, '0');
  return h > 0 ? '$h:${two(m)}:${two(sec)}' : '${two(m)}:${two(sec)}';
}

/// Odmiana: 1 pudełko, 2–4 pudełka, 5 pudełek (12–14 też „pudełek").
String boxesWord(int n) {
  if (n == 1) return 'pudełko';
  final last = n % 10, last2 = n % 100;
  if (last >= 2 && last <= 4 && (last2 < 12 || last2 > 14)) return 'pudełka';
  return 'pudełek';
}
