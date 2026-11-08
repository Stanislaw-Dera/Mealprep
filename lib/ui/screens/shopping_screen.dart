import 'package:flutter/material.dart';

import '../../data/database.dart';
import '../../logic/scaling.dart';
import '../../logic/session.dart';
import '../../logic/session_plan.dart';
import '../../logic/shopping.dart';
import '../app_scope.dart';

/// Zakładka „Zakupy": lista dla wybranej sesji, po działach Biedronki,
/// z odhaczaniem.
///
/// Ekran słucha bazy przez strumienie (`watch...`), więc zmiana dania
/// w Planie albo celów w Ustawieniach od razu przelicza listę.
class ShoppingScreen extends StatefulWidget {
  const ShoppingScreen({super.key});

  @override
  State<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends State<ShoppingScreen> {
  AppDatabase? _db;
  late Stream<List<SessionPlan>> _sessions;
  late Stream<Settings> _settings;

  /// Strumień odhaczeń dla aktualnej sesji; tworzony na nowo przy zmianie sesji.
  Stream<Set<String>>? _checks;
  int? _checksFor;

  /// Sesja wybrana ręcznie. `null` = domyślna (najbliższa).
  int? _selectedId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final db = AppScope.of(context).db;
    if (db != _db) {
      _db = db;
      _sessions = db.watchSessions();
      _settings = db.watchSettings();
      _checks = null;
      _checksFor = null;
    }
  }

  Stream<Set<String>> _checksOf(int sessionId) {
    if (_checksFor != sessionId) {
      _checksFor = sessionId;
      _checks = _db!.watchChecks(sessionId);
    }
    return _checks!;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SessionPlan>>(
      stream: _sessions,
      builder: (context, sessionsSnap) => StreamBuilder<Settings>(
        stream: _settings,
        builder: (context, settingsSnap) {
          final sessions = sessionsSnap.data;
          final settings = settingsSnap.data;
          if (sessions == null || settings == null) {
            return _scaffold(const Center(child: CircularProgressIndicator()));
          }
          if (sessions.isEmpty) {
            return _scaffold(
              _message(
                'Zaplanuj sesję w zakładce Plan, a tu pojawi się lista.',
              ),
            );
          }
          final session =
              sessions.where((s) => s.id == _selectedId).firstOrNull ??
              defaultShoppingSession(sessions, DateTime.now())!;
          return StreamBuilder<Set<String>>(
            stream: _checksOf(session.id!),
            builder: (context, checksSnap) => _content(
              sessions,
              session,
              settings,
              checksSnap.data ?? const {},
            ),
          );
        },
      ),
    );
  }

  Widget _scaffold(Widget body, {SessionPlan? session}) => Scaffold(
    appBar: AppBar(
      title: const Text('Zakupy'),
      actions: [
        if (session != null)
          PopupMenuButton<void>(
            tooltip: 'Więcej',
            itemBuilder: (_) => [
              PopupMenuItem(
                onTap: () => _db!.clearChecks(session.id!),
                child: const Text('Odznacz wszystko'),
              ),
            ],
          ),
      ],
    ),
    body: body,
  );

  Widget _message(String text) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(text, textAlign: TextAlign.center),
    ),
  );

  Widget _content(
    List<SessionPlan> sessions,
    SessionPlan session,
    Settings settings,
    Set<String> checked,
  ) {
    final catalog = AppScope.of(context).catalog;
    final theme = Theme.of(context);
    final portions = planSession(settings, session.toSession(), catalog);
    final list = shoppingList(portions, catalog);
    final catNames = {for (final c in catalog.categories) c.id: c.name};

    final buyItems = [for (final g in list.groups) ...g.items];
    final bought = buyItems.where((i) => checked.contains(i.productId)).length;

    final children = <Widget>[
      _sessionPicker(theme, sessions, session),
      if (portions.isEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 32),
          child: _message(
            'W tej sesji nie wybrano jeszcze dań. Wybierz je w zakładce Plan.',
          ),
        )
      else ...[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kupione $bought z ${buyItems.length}',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: buyItems.isEmpty ? 0 : bought / buyItems.length,
              ),
            ],
          ),
        ),
        for (final g in list.groups) ...[
          _header(theme, catNames[g.categoryId] ?? g.categoryId),
          for (final i in g.items)
            _itemTile(
              theme,
              session,
              i,
              checked.contains(i.productId),
              trailing: i.label,
            ),
        ],
        if (list.check.isNotEmpty) ...[
          _header(theme, 'Sprawdź, czy masz'),
          for (final i in list.check)
            _itemTile(theme, session, i, checked.contains(i.productId)),
        ],
      ],
    ];

    return _scaffold(
      session: session,
      Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: children,
          ),
        ),
      ),
    );
  }

  Widget _sessionPicker(
    ThemeData theme,
    List<SessionPlan> sessions,
    SessionPlan session,
  ) {
    String label(SessionPlan s) =>
        'Sesja ${dayLabel(s.firstDay)} – ${dayLabel(s.lastDay)}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: sessions.length == 1
          ? Text(label(session), style: theme.textTheme.titleMedium)
          : DropdownButton<int>(
              value: session.id,
              isExpanded: true,
              onChanged: (id) => setState(() => _selectedId = id),
              items: [
                for (final s in sessions)
                  DropdownMenuItem(value: s.id, child: Text(label(s))),
              ],
            ),
    );
  }

  Widget _header(ThemeData theme, String text) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
    child: Text(
      text,
      style: theme.textTheme.titleSmall?.copyWith(
        color: theme.colorScheme.primary,
      ),
    ),
  );

  Widget _itemTile(
    ThemeData theme,
    SessionPlan session,
    ShoppingItem item,
    bool isChecked, {
    String? trailing,
  }) {
    final done = isChecked
        ? TextStyle(
            decoration: TextDecoration.lineThrough,
            color: theme.colorScheme.onSurfaceVariant,
          )
        : null;
    void toggle() => _db!.setChecked(session.id!, item.productId, !isChecked);
    return ListTile(
      dense: true,
      leading: Checkbox(value: isChecked, onChanged: (_) => toggle()),
      title: Text(item.name, style: done),
      subtitle: Text('potrzeba ${_g(item.needG)} g'),
      trailing: trailing == null
          ? null
          : Text(trailing, style: theme.textTheme.titleSmall?.merge(done)),
      onTap: toggle,
    );
  }
}

String _g(double g) => g == g.roundToDouble()
    ? g.toInt().toString()
    : g.toStringAsFixed(1).replaceAll('.', ',');
