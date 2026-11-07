import 'package:flutter_test/flutter_test.dart';
import 'package:mealprep/data/asset_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('wbudowana baza ma tyle samo danych co prototyp w Pythonie', () async {
    final data = await AssetData.load();

    // `python3 tools/mealprep_proto.py validate` → 27 przepisów, 130 produktów.
    expect(data.recipes.length, 27);
    expect((data.products['products'] as List).length, 130);
    expect(data.recipes.every((r) => r['format'] == 'mealprep/1'), isTrue);
  });
}
