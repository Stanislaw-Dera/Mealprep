import 'package:flutter/material.dart';

import '../../logic/session_plan.dart';
import '../app_scope.dart';
import 'session_editor_screen.dart';

/// Zakładka „Plan": lista sesji gotowania i przycisk nowej sesji.
class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key});

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  List<SessionPlan>? _sessions;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_sessions == null) _reload();
  }

  Future<void> _reload() async {
    final list = await AppScope.of(context).db.loadSessions();
    if (mounted) setState(() => _sessions = list);
  }

  /// Nowa sesja: dzień po końcu ostatniej (albo dziś) i tyle dni,
  /// żeby z poprzednią dało tydzień (domyślnie 4).
  Future<void> _create() async {
    final db = AppScope.of(context).db;
    final slots = await db.loadMealSlots();
    final last = _sessions!.isEmpty ? null : _sessions!.first;
    final today = dateOnly(DateTime.now());
    var first = today;
    var count = 4;
    if (last != null) {
      final next = last.dateOf(last.days.length);
      if (!next.isBefore(today)) {
        first = next;
        count = (7 - last.days.length).clamp(1, 7);
      }
    }
    final plan = await db.saveSession(
      SessionPlan.create(firstDay: first, dayCount: count, slots: slots),
    );
    if (mounted) await _open(plan);
  }

  Future<void> _open(SessionPlan plan) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SessionEditorScreen(initial: plan),
      ),
    );
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final sessions = _sessions;
    final catalog = AppScope.of(context).catalog;
    return Scaffold(
      appBar: AppBar(title: const Text('Plan')),
      floatingActionButton: sessions == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _create,
              icon: const Icon(Icons.add),
              label: const Text('Nowa sesja'),
            ),
      body: switch (sessions) {
        null => const Center(child: CircularProgressIndicator()),
        [] => const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Nie masz jeszcze żadnej sesji.\n'
              'Kliknij „Nowa sesja", żeby zaplanować gotowanie.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        _ => ListView(
          padding: const EdgeInsets.only(bottom: 88),
          children: [
            for (final s in sessions)
              ListTile(
                leading: const Icon(Icons.soup_kitchen_outlined),
                title: Text(
                  '${dayLabel(s.firstDay)} – ${dayLabel(s.lastDay)} '
                  '· ${s.days.length} ${_dni(s.days.length)}',
                ),
                subtitle: Text(
                  s.recipes.isEmpty
                      ? 'Nie wybrano dań'
                      : [
                          for (final slot in s.prepSlots)
                            if (s.recipes[slot.name] != null)
                              catalog.recipes[s.recipes[slot.name]]?.name ??
                                  '?',
                        ].join(' · '),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _open(s),
              ),
          ],
        ),
      },
    );
  }
}

String _dni(int n) => n == 1 ? 'dzień' : 'dni';
