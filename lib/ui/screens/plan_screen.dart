import 'package:flutter/material.dart';

import '../app_scope.dart';

/// Zakładka „Plan". Na razie lista przepisów z wbudowanej bazy;
/// planowanie sesji to następny krok.
class PlanScreen extends StatelessWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final recipes = AppScope.of(context).catalog.recipes.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return Scaffold(
      appBar: AppBar(title: const Text('Plan')),
      body: ListView(
        children: [
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Planowanie sesji już wkrótce'),
            subtitle: Text('Na razie: przepisy w bazie'),
          ),
          const Divider(),
          for (final r in recipes)
            ListTile(
              title: Text(r.name),
              subtitle: Text(
                '${r.timeMin} min · ${r.prep ? 'do prepu, ${r.fridgeDays} dni w lodówce' : 'na bieżąco'}',
              ),
            ),
        ],
      ),
    );
  }
}
