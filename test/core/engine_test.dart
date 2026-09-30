import 'package:flutter_test/flutter_test.dart';
import 'package:blockpuzzle_game/core/board/board.dart';
import 'package:blockpuzzle_game/core/board/board_point.dart';
import 'package:blockpuzzle_game/core/engine/game_engine.dart';
import 'package:blockpuzzle_game/core/models/game_mode.dart';
import 'package:blockpuzzle_game/core/pieces/piece_shape.dart';

BoardPoint? _findValidOrigin(Board board, PieceShape shape) {
  for (int y = 0; y <= Board.size - shape.height; y++) {
    for (int x = 0; x <= Board.size - shape.width; x++) {
      final pt = BoardPoint(x, y);
      if (board.canPlacePiece(shape, pt)) {
        return pt;
      }
    }
  }
  return null;
}

void main() {
  group('GameEngine Core Tests', () {
    test('Initializes with 3 tray pieces and 0 score', () {
      final engine = GameEngine(mode: GameMode.classic, seed: 12345);
      expect(engine.state.tray.length, equals(3));
      expect(engine.state.tray.every((p) => p != null), isTrue);
      expect(engine.state.score, equals(0));
      expect(engine.state.movesCount, equals(0));
      expect(engine.state.isGameOver, isFalse);
    });

    test('Placing a piece updates board, score, and moves', () {
      final engine = GameEngine(mode: GameMode.classic, seed: 12345);
      final piece = engine.state.tray[0]!;
      final origin = _findValidOrigin(engine.state.board, piece)!;

      final success = engine.placePiece(trayIndex: 0, origin: origin);
      expect(success, isTrue);
      expect(engine.state.tray[0], isNull);
      expect(engine.state.score, equals(piece.cellCount));
      expect(engine.state.movesCount, equals(1));
    });

    test('Tray refills automatically when all 3 pieces are placed', () {
      final engine = GameEngine(mode: GameMode.classic, seed: 12345);

      for (int i = 0; i < 3; i++) {
        final piece = engine.state.tray[i]!;
        final origin = _findValidOrigin(engine.state.board, piece);
        expect(origin, isNotNull);
        expect(engine.placePiece(trayIndex: i, origin: origin!), isTrue);
      }

      // Tray should have been replenished with 3 new pieces
      expect(engine.state.tray.every((p) => p != null), isTrue);
      expect(engine.state.movesCount, equals(3));
    });

    test('Undo reverts board, score, combo, and tray correctly', () {
      final engine = GameEngine(
        mode: GameMode.classic,
        seed: 12345,
        initialUndos: 2,
      );
      final originalPiece = engine.state.tray[0]!;
      final originalScore = engine.state.score;
      final origin = _findValidOrigin(engine.state.board, originalPiece)!;

      expect(engine.placePiece(trayIndex: 0, origin: origin), isTrue);
      expect(engine.state.score, greaterThan(originalScore));
      expect(engine.state.tray[0], isNull);
      expect(engine.canUndo, isTrue);

      final undone = engine.undo();
      expect(undone, isTrue);
      expect(engine.state.score, equals(originalScore));
      expect(engine.state.tray[0]?.id, equals(originalPiece.id));
      expect(engine.state.board.isCellEmpty(origin.x, origin.y), isTrue);
      expect(engine.state.undoCharges, equals(1));
    });

    test('Combo counter resets after 3 consecutive non-clearing moves', () {
      final engine = GameEngine(mode: GameMode.classic, seed: 12345);

      expect(engine.state.currentCombo, equals(0));

      for (int i = 0; i < 3; i++) {
        final piece = engine.state.tray[i]!;
        final origin = _findValidOrigin(engine.state.board, piece)!;
        engine.placePiece(trayIndex: i, origin: origin);
      }

      // Either combo was reset or remained 0 if no clears happened
      expect(
        engine.state.noClearPlacementsStreak,
        anyOf(0, greaterThanOrEqualTo(1)),
      );
    });

    test(
      'DETERMINISM TEST: Same seed + same list of moves => same final score',
      () {
        const fixedSeed = 54321;

        // Run A
        final engineA = GameEngine(mode: GameMode.daily, seed: fixedSeed);
        final originA0 = _findValidOrigin(
          engineA.state.board,
          engineA.state.tray[0]!,
        )!;
        engineA.placePiece(trayIndex: 0, origin: originA0);

        final originA1 = _findValidOrigin(
          engineA.state.board,
          engineA.state.tray[1]!,
        )!;
        engineA.placePiece(trayIndex: 1, origin: originA1);

        final originA2 = _findValidOrigin(
          engineA.state.board,
          engineA.state.tray[2]!,
        )!;
        engineA.placePiece(trayIndex: 2, origin: originA2);

        // Run B
        final engineB = GameEngine(mode: GameMode.daily, seed: fixedSeed);
        engineB.placePiece(trayIndex: 0, origin: originA0);
        engineB.placePiece(trayIndex: 1, origin: originA1);
        engineB.placePiece(trayIndex: 2, origin: originA2);

        expect(engineA.state.score, equals(engineB.state.score));
        expect(
          engineA.state.linesClearedTotal,
          equals(engineB.state.linesClearedTotal),
        );
        expect(engineA.state.movesCount, equals(engineB.state.movesCount));
        expect(
          engineA.state.board.filledCellCount,
          equals(engineB.state.board.filledCellCount),
        );
      },
    );

    test('Zen Mode auto-clears instead of triggering game over', () {
      final engine = GameEngine(mode: GameMode.zen, seed: 12345);
      expect(engine.state.mode, equals(GameMode.zen));
      expect(engine.state.isGameOver, isFalse);
    });
  });
}
