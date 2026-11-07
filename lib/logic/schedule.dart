/// Wspólny plan sesji: port `schedule_session` z tools/mealprep_proto.py.
///
/// Symulacja w czasie (minuty) dla 1 osoby (ręce) i N palników:
/// - krok aktywny zajmuje ręce przez cały czas trwania,
/// - krok pasywny (np. gotowanie ryżu) zajmuje ręce tylko na 1 min startu,
/// - krok z `burner` zajmuje palnik do końca.
/// Gdy ręce są wolne, startujemy gotowy krok o najdłuższej ścieżce do końca
/// swojego przepisu (critical path), żeby długie gotowanie ruszyło wcześnie.
library;

import 'models.dart';

class ScheduledStep {
  ScheduledStep._({
    required this.recipeId,
    required this.stepNo,
    required this.step,
    required this.deps,
  });

  final String recipeId;

  /// Numer kroku w przepisie (od 1).
  final int stepNo;
  final RecipeStep step;
  final List<String> deps;

  int prio = 0;
  int start = 0;
  int end = 0;

  String get key => _key(recipeId, stepNo);
  String get text => step.text;
  int get minutes => step.minutes;
  bool get passive => step.passive;
  bool get burner => step.burner;
}

String _key(String rid, int no) => '$rid#$no';

class SessionSchedule {
  const SessionSchedule({
    required this.plan,
    required this.total,
    required this.sequential,
  });

  /// Kroki w kolejności rozpoczęcia, z czasami start/end.
  final List<ScheduledStep> plan;

  /// Łączny czas sesji w minutach.
  final int total;

  /// Ile by trwało robienie kroków po kolei, bez przeplatania.
  final int sequential;
}

SessionSchedule scheduleSession(
  List<String> recipeIds,
  Map<String, Recipe> recipes, {
  int burners = 4,
}) {
  final tasks = <ScheduledStep>[];
  for (final rid in recipeIds) {
    final steps = recipes[rid]!.steps;
    for (var i = 1; i <= steps.length; i++) {
      final s = steps[i - 1];
      final deps = s.after ?? (i > 1 ? [i - 1] : <int>[]);
      tasks.add(
        ScheduledStep._(
          recipeId: rid,
          stepNo: i,
          step: s,
          deps: [for (final d in deps) _key(rid, d)],
        ),
      );
    }
  }

  // Critical path: czas tego kroku + najdłuższa ścieżka przez kroki zależne.
  final memo = <String, int>{};
  int tail(ScheduledStep t) {
    final cached = memo[t.key];
    if (cached != null) return cached;
    var best = 0;
    for (final u in tasks) {
      if (u.deps.contains(t.key)) {
        final v = tail(u);
        if (v > best) best = v;
      }
    }
    return memo[t.key] = t.minutes + best;
  }

  for (final t in tasks) {
    t.prio = tail(t);
  }

  var time = 0, handsFree = 0;
  final running = <ScheduledStep>[];
  final done = <String>{};
  final plan = <ScheduledStep>[];
  final pending = [...tasks];

  while (pending.isNotEmpty || running.isNotEmpty) {
    for (final t in running.where((t) => t.end <= time).toList()) {
      running.remove(t);
      done.add(t.key);
    }
    if (pending.isEmpty && running.isEmpty) break;

    if (handsFree <= time) {
      final used = running.where((t) => t.burner).length;
      ScheduledStep? pick;
      for (final t in pending) {
        final ready =
            t.deps.every(done.contains) && !(t.burner && used >= burners);
        // Przy równym priorytecie wygrywa pierwszy (jak max() w Pythonie).
        if (ready && (pick == null || t.prio > pick.prio)) pick = t;
      }
      if (pick != null) {
        pick.start = time;
        pick.end = time + pick.minutes;
        handsFree = time + (pick.passive ? 1 : pick.minutes);
        running.add(pick);
        pending.remove(pick);
        plan.add(pick);
        continue;
      }
    }

    final events = [
      for (final t in running)
        if (t.end > time) t.end,
      if (handsFree > time) handsFree,
    ];
    if (events.isEmpty) {
      throw StateError("zakleszczenie w planie sesji (sprawdź pola 'after')");
    }
    time = events.reduce((a, b) => a < b ? a : b);
  }

  final total = plan.map((t) => t.end).reduce((a, b) => a > b ? a : b);
  final seq = tasks.fold(0, (s, t) => s + t.minutes);
  return SessionSchedule(plan: plan, total: total, sequential: seq);
}
