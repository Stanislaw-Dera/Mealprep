import 'package:flutter/material.dart';

import 'data/asset_data.dart';

void main() {
  runApp(const MealprepApp());
}

class MealprepApp extends StatelessWidget {
  const MealprepApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Colors.green;
    return MaterialApp(
      title: 'Mealprep',
      debugShowCheckedModeBanner: false,
      // Motyw jasny lub ciemny, zgodnie z ustawieniem systemu.
      themeMode: ThemeMode.system,
      theme: ThemeData(colorSchemeSeed: seed, brightness: Brightness.light),
      darkTheme: ThemeData(colorSchemeSeed: seed, brightness: Brightness.dark),
      home: const HomeScreen(),
    );
  }
}

/// Tymczasowy ekran startowy: pokazuje, że wbudowana baza się wczytała.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Future<AssetData> _data = AssetData.load();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mealprep')),
      body: FutureBuilder<AssetData>(
        future: _data,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Błąd wczytywania danych: ${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snap.data!;
          final productCount = (data.products['products'] as List).length;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Baza wczytana: ${data.recipes.length} przepisów, '
                '$productCount produktów',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              for (final r in data.recipes) ListTile(title: Text(r['name'])),
            ],
          );
        },
      ),
    );
  }
}
