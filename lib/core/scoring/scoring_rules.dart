/// Pure Dart scoring rules and calculation constants for Prism Blocks.
/// Single source of truth for all score computations.
abstract final class ScoringRules {
  /// Points awarded per cell placed on board.
  static const int pointsPerCellPlaced = 1;

  /// Base multiplier for quadratic line clearing.
  static const int lineClearBaseMultiplier = 10;

  /// Bonus points awarded when board is left completely empty after a clear.
  static const int perfectClearBonus = 300;

  /// Combo multiplier step per consecutive clearing placement.
  static const double comboMultiplierStep = 0.5;

  /// Maximum combo multiplier cap.
  static const double maxComboMultiplier = 5.0;

  /// Consecutive non-clearing placements before combo count drops to 0.
  static const int comboGracePlacements = 3;

  /// Computes line clear points using quadratic scaling: lines * 10 * lines.
  static int calculateLineClearPoints(int linesCleared) {
    if (linesCleared <= 0) return 0;
    return linesCleared * lineClearBaseMultiplier * linesCleared;
  }

  /// Computes the combo multiplier based on consecutive clearing placements.
  /// 1 clear => 1.0x, 2 clears => 1.5x, 3 clears => 2.0x, ... capped at 5.0x.
  static double getComboMultiplier(int comboCount) {
    if (comboCount <= 1) return 1.0;
    final mult = 1.0 + (comboMultiplierStep * (comboCount - 1));
    return mult > maxComboMultiplier ? maxComboMultiplier : mult;
  }

  /// Calculates total points for a placement move given lines cleared, combo, and perfect clear status.
  static MoveScoreResult calculateScore({
    required int cellsPlaced,
    required int linesCleared,
    required int currentCombo,
    required bool isPerfectClear,
  }) {
    final placementPoints = cellsPlaced * pointsPerCellPlaced;
    final linePoints = calculateLineClearPoints(linesCleared);
    final comboMultiplier = getComboMultiplier(currentCombo);

    final scaledLinePoints = (linePoints * comboMultiplier).round();
    final perfectClearPoints = isPerfectClear ? perfectClearBonus : 0;

    final totalEarned = placementPoints + scaledLinePoints + perfectClearPoints;

    return MoveScoreResult(
      placementPoints: placementPoints,
      linePoints: scaledLinePoints,
      perfectClearBonus: perfectClearPoints,
      comboMultiplier: comboMultiplier,
      totalEarned: totalEarned,
    );
  }
}

class MoveScoreResult {
  final int placementPoints;
  final int linePoints;
  final int perfectClearBonus;
  final double comboMultiplier;
  final int totalEarned;

  const MoveScoreResult({
    required this.placementPoints,
    required this.linePoints,
    required this.perfectClearBonus,
    required this.comboMultiplier,
    required this.totalEarned,
  });

  @override
  String toString() =>
      'MoveScoreResult(total: $totalEarned, placement: $placementPoints, line: $linePoints, perfect: $perfectClearBonus, combo: ${comboMultiplier}x)';
}
