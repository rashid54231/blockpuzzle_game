import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:blockpuzzle_game/app/providers.dart';
import 'package:blockpuzzle_game/features/home/home_screen.dart';
import 'package:blockpuzzle_game/shared/constants/game_constants.dart';

void main() {
  testWidgets('HomeScreen displays title, currencies, and mode buttons', (
    WidgetTester tester,
  ) async {
    final nowUtc = DateTime.now().toUtc();
    final todayStr =
        '${nowUtc.year}-${nowUtc.month.toString().padLeft(2, '0')}-${nowUtc.day.toString().padLeft(2, '0')}';

    SharedPreferences.setMockInitialValues({
      'player_progress_v1':
          '{"coins":250,"gems":15,"bestClassicScore":1200,"unlockedThemes":["neon"],"selectedTheme":"neon","lastLoginDate":"$todayStr"}',
    });
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 950));

    // Verify title
    expect(find.text(GameConstants.appTitle), findsOneWidget);

    // Verify currencies
    expect(find.text('250'), findsOneWidget);
    expect(find.text('15'), findsOneWidget);

    // Verify game modes
    expect(find.text('PLAY CLASSIC'), findsOneWidget);
    expect(find.text('DAILY'), findsOneWidget);
    expect(find.text('ZEN'), findsOneWidget);

    // Verify navigation tabs
    expect(find.text('Themes'), findsOneWidget);
    expect(find.text('Shop'), findsOneWidget);
    expect(find.text('Ranks'), findsOneWidget);
    expect(find.text('Badges'), findsOneWidget);
    expect(find.text('Stats'), findsOneWidget);
  });
}
