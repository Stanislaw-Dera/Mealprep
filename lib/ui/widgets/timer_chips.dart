import 'package:flutter/material.dart';

import '../../logic/cooking.dart';
import '../app_scope.dart';
import '../cooking_timers.dart';

/// Pasek z minutnikami „w użyciu" (chodzą, pauza albo skończone).
/// Przerysowuje się sam co sekundę, gdy coś chodzi.
class TimerChips extends StatelessWidget {
  const TimerChips({super.key, this.exclude, this.onTap, this.padding});

  /// Minutnik, którego nie pokazujemy (np. ten z oglądanego kroku).
  final CookingTimer? exclude;

  /// Kliknięcie w minutnik (np. przejście do jego kroku).
  final void Function(CookingTimer t)? onTap;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final timers = AppScope.of(context).timers;
    return ListenableBuilder(
      listenable: timers,
      builder: (context, _) {
        final list = timers.active.where((t) => t != exclude).toList();
        if (list.isEmpty) return const SizedBox.shrink();
        final now = timers.clock();
        final theme = Theme.of(context);
        return Padding(
          padding: padding ?? const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final t in list)
                InputChip(
                  avatar: Icon(
                    t.timer.finished(now)
                        ? Icons.alarm_on
                        : t.timer.running
                        ? Icons.timer_outlined
                        : Icons.pause,
                    size: 18,
                  ),
                  label: Text(
                    '${_short(t.recipe.name)} · krok ${t.step + 1} · '
                    '${t.timer.finished(now) ? 'gotowe' : formatDuration(t.timer.remaining(now))}',
                  ),
                  backgroundColor: t.timer.finished(now)
                      ? theme.colorScheme.errorContainer
                      : null,
                  onPressed: onTap == null ? null : () => onTap!(t),
                  // Skończony albo zapauzowany minutnik można zamknąć.
                  onDeleted: t.timer.running ? null : () => timers.reset(t),
                  deleteButtonTooltipMessage: 'Zamknij minutnik',
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Pierwsze słowa nazwy dania, żeby chip nie był za długi.
String _short(String name) {
  final words = name.split(' ');
  return words.length <= 2 ? name : '${words.take(2).join(' ')}…';
}
