import '../board/board.dart';
import '../pieces/piece_catalog.dart';
import '../pieces/piece_shape.dart';
import 'prng.dart';

/// Intelligent, fair piece generator that ensures game feel:
/// 1. Guaranteed placeability: Tray ALWAYS has at least one piece placeable on current board.
/// 2. Difficulty scaling: Introduces larger pieces gradually as score increases.
/// 3. Rescue bias: Deals smaller/line pieces when board is over 65% full.
/// Pure Dart class with zero Flutter dependencies.
class FairPieceGenerator {
  final Mulberry32 _prng;

  FairPieceGenerator([int seed = 123456789]) : _prng = Mulberry32(seed);

  Mulberry32 get prng => _prng;

  /// Generates a set of [count] pieces (typically 3) for the player's tray.
  List<PieceShape> generateTray(
    Board currentBoard,
    int currentScore, {
    int count = 3,
  }) {
    final List<PieceShape> tray = [];

    // Categorize shapes by tier/size
    final smallShapes = [
      PieceCatalog.dot,
      PieceCatalog.line2H,
      PieceCatalog.line2V,
      PieceCatalog.diagDown,
      PieceCatalog.diagUp,
      PieceCatalog.corner2TopLeft,
      PieceCatalog.corner2TopRight,
      PieceCatalog.corner2BottomLeft,
      PieceCatalog.corner2BottomRight,
    ];

    final mediumShapes = [
      PieceCatalog.line3H,
      PieceCatalog.line3V,
      PieceCatalog.square2,
      PieceCatalog.rect2x3,
      PieceCatalog.rect3x2,
      PieceCatalog.tUp,
      PieceCatalog.tDown,
      PieceCatalog.tLeft,
      PieceCatalog.tRight,
      PieceCatalog.sShapeH,
      PieceCatalog.zShapeH,
    ];

    final largeShapes = [
      PieceCatalog.line4H,
      PieceCatalog.line4V,
      PieceCatalog.line5H,
      PieceCatalog.line5V,
      PieceCatalog.square3,
      PieceCatalog.corner3TopLeft,
      PieceCatalog.corner3TopRight,
      PieceCatalog.corner3BottomLeft,
      PieceCatalog.corner3BottomRight,
    ];

    final fullnessRatio =
        currentBoard.filledCellCount / (Board.size * Board.size);
    final isBoardNearFull = fullnessRatio > 0.65;

    for (int i = 0; i < count; i++) {
      List<PieceShape> candidatePool;

      if (isBoardNearFull) {
        // Rescue bias: favor small shapes (70%) and medium shapes (30%)
        final roll = _prng.nextDouble();
        if (roll < 0.70) {
          candidatePool = smallShapes;
        } else {
          candidatePool = mediumShapes;
        }
      } else if (currentScore < 500) {
        // Early game: small and medium pieces
        final roll = _prng.nextDouble();
        if (roll < 0.50) {
          candidatePool = smallShapes;
        } else if (roll < 0.85) {
          candidatePool = mediumShapes;
        } else {
          candidatePool = largeShapes;
        }
      } else if (currentScore < 1500) {
        // Mid game: balanced distribution
        final roll = _prng.nextDouble();
        if (roll < 0.30) {
          candidatePool = smallShapes;
        } else if (roll < 0.70) {
          candidatePool = mediumShapes;
        } else {
          candidatePool = largeShapes;
        }
      } else {
        // Late game: more challenging shapes
        final roll = _prng.nextDouble();
        if (roll < 0.20) {
          candidatePool = smallShapes;
        } else if (roll < 0.55) {
          candidatePool = mediumShapes;
        } else {
          candidatePool = largeShapes;
        }
      }

      final chosen = candidatePool[_prng.nextInt(0, candidatePool.length - 1)];
      tray.add(chosen);
    }

    // CRITICAL FAIRNESS RULE:
    // Guarantee that at least one piece in the tray can be placed on currentBoard.
    bool atLeastOnePlaceable = false;
    for (final piece in tray) {
      if (currentBoard.canPlacePieceAnywhere(piece)) {
        atLeastOnePlaceable = true;
        break;
      }
    }

    if (!atLeastOnePlaceable) {
      // Find all shapes from catalog placeable on current board
      final placeableShapes = <PieceShape>[];
      for (final shape in PieceCatalog.all) {
        if (currentBoard.canPlacePieceAnywhere(shape)) {
          placeableShapes.add(shape);
        }
      }

      if (placeableShapes.isNotEmpty) {
        // Replace the last piece with a placeable shape
        final rescuePiece =
            placeableShapes[_prng.nextInt(0, placeableShapes.length - 1)];
        tray[tray.length - 1] = rescuePiece;
      }
    }

    return tray;
  }
}
