import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:blockpuzzle_game/app/providers.dart';
import 'package:blockpuzzle_game/core/models/game_mode.dart';
import 'package:blockpuzzle_game/features/play/play_screen.dart';

void main() {
  testWidgets('PlayScreen renders HUD with score, undo, and pause buttons', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const MaterialApp(
          home: PlayScreen(mode: GameMode.classic, seed: 12345),
        ),
      ),
    );

    await tester.pump();

    // Verify HUD elements
    expect(find.text('SCORE'), findsOneWidget);
    expect(find.text('BEST'), findsOneWidget);
    expect(find.byIcon(Icons.pause_circle_outline), findsOneWidget);
    expect(find.byIcon(Icons.undo), findsOneWidget);

    // Open pause menu
    await tester.tap(find.byIcon(Icons.pause_circle_outline));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Game Paused'), findsOneWidget);
    expect(find.text('RESUME'), findsOneWidget);
    expect(find.text('Exit to Home'), findsOneWidget);
  });
}
