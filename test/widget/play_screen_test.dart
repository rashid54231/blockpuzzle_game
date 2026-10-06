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
    expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
    expect(find.byIcon(Icons.undo_rounded), findsOneWidget);

    // Open pause menu
    await tester.tap(find.byIcon(Icons.pause_rounded));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('PAUSED'), findsOneWidget);
    expect(find.text('RESUME GAME'), findsOneWidget);
    expect(find.text('Exit to Home'), findsOneWidget);
  });
}
