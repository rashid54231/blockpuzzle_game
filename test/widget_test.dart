import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:blockpuzzle_game/main.dart';
import 'package:blockpuzzle_game/app/providers.dart';
import 'package:blockpuzzle_game/shared/constants/game_constants.dart';

void main() {
  testWidgets('Prism Blocks App smoke launch test', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const PrismBlocksApp(),
      ),
    );

    // Initial pump
    await tester.pump();

    // Verify title appears on splash or app launches
    expect(find.text(GameConstants.appTitle), findsOneWidget);
  });
}
