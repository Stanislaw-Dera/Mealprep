import 'dart:async';

import 'package:flutter/foundation.dart';

import '../logic/cooking.dart';
import '../logic/models.dart';

/// Minutnik jednego kroku jednego dania.
class CookingTimer {
  CookingTimer._(this.recipe, this.step)
    : timer = StepTimer(Duration(minutes: recipe.steps[step].minutes));

  final Recipe recipe;

  /// Numer kroku (od 0).
  final int step;
  final StepTimer timer;

  /// Czy już powiadomiliśmy o końcu (dźwięk i komunikat tylko raz).
  bool announced = false;

  String get key => _key(recipe.id, step);
}

String _key(String recipeId, int step) => '$recipeId#$step';

/// Wszystkie minutniki w aplikacji.
///
/// Żyje tak długo jak aplikacja (tworzy go `MealprepApp`), więc minutniki
/// chodzą dalej po wyjściu z ekranu dania i w kilku daniach naraz.
/// `ChangeNotifier` powiadamia ekrany o zmianach (co sekundę, gdy coś chodzi),
/// a ekrany przerysowują się przez `ListenableBuilder`.
class CookingTimers extends ChangeNotifier {
  CookingTimers({this.onFinished, DateTime Function()? clock})
    : clock = clock ?? DateTime.now;

  /// Wołane raz, gdy minutnik dojdzie do zera (dźwięk, komunikat).
  final void Function(CookingTimer t)? onFinished;
  final DateTime Function() clock;

  final _timers = <String, CookingTimer>{};
  Timer? _ticker;

  /// Minutnik kroku (tworzony przy pierwszym użyciu).
  CookingTimer of(Recipe recipe, int step) => _timers.putIfAbsent(
    _key(recipe.id, step),
    () => CookingTimer._(recipe, step),
  );

  /// Minutniki „w użyciu": chodzące, zapauzowane w trakcie albo skończone,
  /// których jeszcze nie zamknięto. W kolejności uruchamiania.
  List<CookingTimer> get active {
    final now = clock();
    return [
      for (final t in _timers.values)
        if (t.timer.started(now)) t,
    ];
  }

  int get runningCount => _timers.values.where((t) => t.timer.running).length;

  void startPause(CookingTimer t) {
    final now = clock();
    t.timer.running ? t.timer.pause(now) : t.timer.start(now);
    _changed();
  }

  /// Od nowa (albo zamknięcie skończonego minutnika).
  void reset(CookingTimer t) {
    t.timer.reset();
    t.announced = false;
    _changed();
  }

  void _changed() {
    final anyRunning = _timers.values.any((t) => t.timer.running);
    if (anyRunning && _ticker == null) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) => tick());
    } else if (!anyRunning) {
      _ticker?.cancel();
      _ticker = null;
    }
    notifyListeners();
  }

  /// Raz na sekundę: zatrzymaj skończone minutniki i powiadom o nich.
  @visibleForTesting
  void tick() {
    final now = clock();
    for (final t in _timers.values) {
      if (t.timer.running && t.timer.finished(now)) {
        t.timer.pause(now);
        if (!t.announced) {
          t.announced = true;
          onFinished?.call(t);
        }
      }
    }
    _changed();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
