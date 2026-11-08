import 'package:flutter/material.dart';

import '../../data/database.dart';
import '../../logic/scaling.dart';
import '../../logic/session.dart';
import '../../logic/session_plan.dart';
import '../app_scope.dart';

/// Dane wybranej sesji, przeliczone na porcje.
class SessionData {
  const SessionData({
    required this.db,
    required this.session,
    required this.settings,
    required this.portions,
  });

  final AppDatabase db;
  final SessionPlan session;
  final Settings settings;
  final List<Portion> portions;
}

/// Wspólny szkielet zakładek Zakupy i Gotowanie: słucha sesji i celów
/// w bazie, wybiera sesję (domyślnie najbliższą, z możliwością zmiany),
/// liczy porcje i pokazuje komunikaty, gdy nie ma czego pokazać.
class SessionView extends StatefulWidget {
  const SessionView({
    super.key,
    required this.title,
    required this.emptyText,
    required this.builder,
    this.actions,
    this.maxWidth = 720,
  });

  final String title;

  /// Tekst, gdy nie ma żadnej sesji.
  final String emptyText;

  /// Treść pod wyborem sesji (gdy sesja ma wybrane dania).
  final List<Widget> Function(BuildContext context, SessionData data) builder;

  /// Przyciski w pasku tytułu dla wybranej sesji.
  final List<Widget> Function(SessionData data)? actions;
  final double maxWidth;

  @override
  State<SessionView> createState() => _SessionViewState();
}

class _SessionViewState extends State<SessionView> {
  AppDatabase? _db;
  late Stream<List<SessionPlan>> _sessions;
  late Stream<Settings> _settings;

  /// Sesja wybrana ręcznie. `null` = domyślna (najbliższa).
  int? _selectedId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final db = AppScope.of(context).db;
    if (db != _db) {
      _db = db;
      // Strumienie tworzymy raz; w build() dostałyby nowe subskrypcje
      // przy każdym przerysowaniu.
      _sessions = db.watchSessions();
      _settings = db.watchSettings();
    }
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
          if (sessions.isEmpty) return _scaffold(_message(widget.emptyText));

          final session =
              sessions.where((s) => s.id == _selectedId).firstOrNull ??
              defaultShoppingSession(sessions, DateTime.now())!;
          final catalog = AppScope.of(context).catalog;
          final data = SessionData(
            db: _db!,
            session: session,
            settings: settings,
            portions: planSession(settings, session.toSession(), catalog),
          );

          return _scaffold(
            actions: widget.actions?.call(data),
            Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: widget.maxWidth),
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 32),
                  children: [
                    _picker(Theme.of(context), sessions, session),
                    if (data.portions.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 32),
                        child: _message(
                          'W tej sesji nie wybrano jeszcze dań. '
                          'Wybierz je w zakładce Plan.',
                        ),
                      )
                    else
                      ...widget.builder(context, data),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _scaffold(Widget body, {List<Widget>? actions}) => Scaffold(
    appBar: AppBar(title: Text(widget.title), actions: actions),
    body: body,
  );

  Widget _message(String text) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(text, textAlign: TextAlign.center),
    ),
  );

  Widget _picker(
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
}
