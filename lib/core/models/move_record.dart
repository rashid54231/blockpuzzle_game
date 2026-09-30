import '../board/board.dart';
import '../board/board_point.dart';
import '../pieces/piece_shape.dart';

/// Immutable snapshot of a placement move for exact undo operations.
/// Pure Dart class with zero Flutter dependencies.
class MoveRecord {
  final int moveIndex;
  final PieceShape pieceShape;
  final int trayIndex;
  final BoardPoint origin;
  final int linesCleared;
  final int scoreEarned;
  final Board previousBoard;
  final int previousScore;
  final int previousCombo;
  final int previousNoClearStreak;
  final List<PieceShape?> previousTray;

  const MoveRecord({
    required this.moveIndex,
    required this.pieceShape,
    required this.trayIndex,
    required this.origin,
    required this.linesCleared,
    required this.scoreEarned,
    required this.previousBoard,
    required this.previousScore,
    required this.previousCombo,
    required this.previousNoClearStreak,
    required this.previousTray,
  });
}
