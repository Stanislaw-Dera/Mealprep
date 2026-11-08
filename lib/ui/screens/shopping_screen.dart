import 'package:flutter/material.dart';

import '../../logic/cooking.dart';
import '../../logic/shopping.dart';
import '../app_scope.dart';
import '../widgets/session_view.dart';

/// Zakładka „Zakupy": lista dla wybranej sesji, po działach Biedronki,
/// z odhaczaniem.
///
/// Ekran słucha bazy przez strumienie (`watch...`), więc zmiana dania
/// w Planie albo celów w Ustawieniach od razu przelicza listę.
class ShoppingScreen extends StatelessWidget {
  const ShoppingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SessionView(
      title: 'Zakupy',
      emptyText: 'Zaplanuj sesję w zakładce Plan, a tu pojawi się lista.',
      actions: (data) => [
        PopupMenuButton<void>(
          tooltip: 'Więcej',
          itemBuilder: (_) => [
            PopupMenuItem(
              onTap: () => data.db.clearChecks(data.session.id!),
              child: const Text('Odznacz wszystko'),
            ),
          ],
        ),
      ],
      builder: (context, data) => [_ShoppingList(data: data)],
    );
  }
}

class _ShoppingList extends StatefulWidget {
  const _ShoppingList({required this.data});

  final SessionData data;

  @override
  State<_ShoppingList> createState() => _ShoppingListState();
}

class _ShoppingListState extends State<_ShoppingList> {
  /// Strumień odhaczeń; tworzony na nowo tylko przy zmianie sesji.
  late Stream<Set<String>> _checks;
  int? _checksFor;

  int get _sessionId => widget.data.session.id!;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void didUpdateWidget(_ShoppingList old) {
    super.didUpdateWidget(old);
    if (_checksFor != _sessionId) _subscribe();
  }

  void _subscribe() {
    _checksFor = _sessionId;
    _checks = widget.data.db.watchChecks(_sessionId);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Set<String>>(
      stream: _checks,
      builder: (context, snap) => _content(context, snap.data ?? const {}),
    );
  }

  Widget _content(BuildContext context, Set<String> checked) {
    final catalog = AppScope.of(context).catalog;
    final theme = Theme.of(context);
    final list = shoppingList(widget.data.portions, catalog);
    final catNames = {for (final c in catalog.categories) c.id: c.name};

    final buyItems = [for (final g in list.groups) ...g.items];
    final bought = buyItems.where((i) => checked.contains(i.productId)).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
              i,
              checked.contains(i.productId),
              trailing: i.label,
            ),
        ],
        if (list.check.isNotEmpty) ...[
          _header(theme, 'Sprawdź, czy masz'),
          for (final i in list.check)
            _itemTile(theme, i, checked.contains(i.productId)),
        ],
      ],
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
    void toggle() =>
        widget.data.db.setChecked(_sessionId, item.productId, !isChecked);
    return ListTile(
      dense: true,
      leading: Checkbox(value: isChecked, onChanged: (_) => toggle()),
      title: Text(item.name, style: done),
      subtitle: Text('potrzeba ${formatGrams(item.needG)} g'),
      trailing: trailing == null
          ? null
          : Text(trailing, style: theme.textTheme.titleSmall?.merge(done)),
      onTap: toggle,
    );
  }
}
