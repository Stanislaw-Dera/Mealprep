import 'package:flutter/material.dart';

import 'screens/placeholder_screen.dart';
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

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  Widget _screen(int i) => switch (i) {
    0 => const PlanScreen(),
    1 => const ShoppingScreen(),
    2 => const PlaceholderScreen(
      title: 'Gotowanie',
      text: 'Tu będzie tryb gotowania: suma składników i kroki z minutnikami.',
    ),
    _ => const SettingsScreen(),
  };

  void _select(int i) => setState(() => _index = i);

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
                for (final t in _tabs)
                  NavigationRailDestination(
                    icon: Icon(t.icon),
                    selectedIcon: Icon(t.selectedIcon),
                    label: Text(t.label),
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
          for (final t in _tabs)
            NavigationDestination(
              icon: Icon(t.icon),
              selectedIcon: Icon(t.selectedIcon),
              label: t.label,
            ),
        ],
      ),
    );
  }
}
