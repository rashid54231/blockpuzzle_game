import 'package:flutter_test/flutter_test.dart';
import 'package:blockpuzzle_game/core/scoring/scoring_rules.dart';

void main() {
  group('Scoring Rules Tests', () {
    test('Placement points equal 1 per cell placed', () {
      final res = ScoringRules.calculateScore(
        cellsPlaced: 5,
        linesCleared: 0,
        currentCombo: 0,
        isPerfectClear: false,
      );
      expect(res.placementPoints, equals(5));
      expect(res.totalEarned, equals(5));
    });

    test('Quadratic line clear scoring formula', () {
      expect(ScoringRules.calculateLineClearPoints(1), equals(10));
      expect(ScoringRules.calculateLineClearPoints(2), equals(40));
      expect(ScoringRules.calculateLineClearPoints(3), equals(90));
      expect(ScoringRules.calculateLineClearPoints(4), equals(160));
      expect(ScoringRules.calculateLineClearPoints(5), equals(250));
    });

    test('Combo multiplier progression and 5x cap', () {
      expect(ScoringRules.getComboMultiplier(0), equals(1.0));
      expect(ScoringRules.getComboMultiplier(1), equals(1.0));
      expect(ScoringRules.getComboMultiplier(2), equals(1.5));
      expect(ScoringRules.getComboMultiplier(3), equals(2.0));
      expect(ScoringRules.getComboMultiplier(4), equals(2.5));
      expect(ScoringRules.getComboMultiplier(9), equals(5.0));
      expect(ScoringRules.getComboMultiplier(20), equals(5.0)); // Capped at 5x
    });

    test(
      'Score calculation combines placement, combo-scaled lines and perfect clear',
      () {
        // 4 cells placed, 2 lines cleared (40 base points), combo 3 (2.0x => 80 points), perfect clear (+300)
        final res = ScoringRules.calculateScore(
          cellsPlaced: 4,
          linesCleared: 2,
          currentCombo: 3,
          isPerfectClear: true,
        );

        expect(res.placementPoints, equals(4));
        expect(res.linePoints, equals(80));
        expect(res.perfectClearBonus, equals(300));
        expect(res.totalEarned, equals(4 + 80 + 300));
      },
    );
  });
}
