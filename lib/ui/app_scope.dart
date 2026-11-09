import 'package:flutter/widgets.dart';

import '../data/database.dart';
import '../logic/models.dart';
import 'cooking_timers.dart';

/// Udostępnia bazę, katalog przepisów i minutniki wszystkim ekranom.
///
/// `InheritedWidget` to wbudowany we Fluttera sposób na przekazanie obiektu
/// w dół drzewa widgetów bez podawania go przez każdy konstruktor.
/// Ekran pobiera go przez `AppScope.of(context)`.
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.db,
    required this.catalog,
    required this.timers,
    required super.child,
  });

  final AppDatabase db;
  final Catalog catalog;
  final CookingTimers timers;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'Brak AppScope nad tym widgetem');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope old) =>
      db != old.db || catalog != old.catalog || timers != old.timers;
}
