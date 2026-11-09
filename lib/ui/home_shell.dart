import 'package:flutter/material.dart';

import 'app_scope.dart';
import 'screens/cooking_screen.dart';
import 'screens/plan_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/shopping_screen.dart';

/// Główny układ: 4 zakładki. Na wąskim ekranie (telefon) dolny pasek,
/// na szerokim (Mac) boczny panel.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _Tab {
  const _Tab(this.label, this.icon, this.selectedIcon);
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

const _tabs = [
  _Tab('Plan', Icons.calendar_month_outlined, Icons.calendar_month),
  _Tab('Zakupy', Icons.shopping_cart_outlined, Icons.shopping_cart),
  _Tab('Gotowanie', Icons.soup_kitchen_outlined, Icons.soup_kitchen),
  _Tab('Ustawienia', Icons.tune_outlined, Icons.tune),
];

/// Od tej szerokości (w punktach) pokazujemy panel boczny zamiast paska.
const _wideBreakpoint = 640.0;

const _cookingTab = 2;

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  Widget _screen(int i) => switch (i) {
    0 => const PlanScreen(),
    1 => const ShoppingScreen(),
    _cookingTab => const CookingScreen(),
    _ => const SettingsScreen(),
  };

  void _select(int i) => setState(() => _index = i);

  /// Ikona zakładki. Gotowanie dostaje licznik działających minutników.
  Widget _icon(int i, {required bool selected}) {
    final icon = Icon(selected ? _tabs[i].selectedIcon : _tabs[i].icon);
    if (i != _cookingTab) return icon;
    final timers = AppScope.of(context).timers;
    return ListenableBuilder(
      listenable: timers,
      builder: (context, _) => Badge(
        isLabelVisible: timers.runningCount > 0,
        label: Text('${timers.runningCount}'),
        child: icon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // IndexedStack trzyma wszystkie zakładki w pamięci, więc po przełączeniu
    // nie tracisz np. niezapisanych zmian w ustawieniach.
    final body = IndexedStack(
      index: _index,
      children: [for (var i = 0; i < _tabs.length; i++) _screen(i)],
    );

    final wide = MediaQuery.sizeOf(context).width >= _wideBreakpoint;
    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: _select,
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (var i = 0; i < _tabs.length; i++)
                  NavigationRailDestination(
                    icon: _icon(i, selected: false),
                    selectedIcon: _icon(i, selected: true),
                    label: Text(_tabs[i].label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: body),
          ],
        ),
      );
    }
    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _select,
        destinations: [
          for (var i = 0; i < _tabs.length; i++)
            NavigationDestination(
              icon: _icon(i, selected: false),
              selectedIcon: _icon(i, selected: true),
              label: _tabs[i].label,
            ),
        ],
      ),
    );
  }
}
