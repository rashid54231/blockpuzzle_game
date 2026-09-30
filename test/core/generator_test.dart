import 'package:flutter_test/flutter_test.dart';
import 'package:blockpuzzle_game/core/board/board.dart';
import 'package:blockpuzzle_game/core/board/board_point.dart';
import 'package:blockpuzzle_game/core/generator/fair_piece_generator.dart';
import 'package:blockpuzzle_game/core/pieces/piece_catalog.dart';

void main() {
  group('FairPieceGenerator Tests', () {
    test('Guarantees at least one placeable piece on the board', () {
      final generator = FairPieceGenerator(42);

      // Create a board with only a single 1x1 cell empty at (0, 0)
      var board = Board();
      for (int y = 0; y < 8; y++) {
        for (int x = 0; x < 8; x++) {
          if (x != 0 || y != 0) {
            board = board.placePiece(PieceCatalog.dot, BoardPoint(x, y), 1);
          }
        }
      }

      // Generate tray
      final tray = generator.generateTray(board, 100);

      // Verify at least one piece can fit in the single remaining spot
      bool hasPlaceable = false;
      for (final piece in tray) {
        if (board.canPlacePieceAnywhere(piece)) {
          hasPlaceable = true;
          break;
        }
      }

      expect(hasPlaceable, isTrue);
    });

    test('Same seed produces identical sequence of trays', () {
      final genA = FairPieceGenerator(9999);
      final genB = FairPieceGenerator(9999);
      final board = Board();

      final trayA1 = genA.generateTray(board, 0);
      final trayB1 = genB.generateTray(board, 0);

      expect(trayA1.map((p) => p.id), equals(trayB1.map((p) => p.id)));

      final trayA2 = genA.generateTray(board, 200);
      final trayB2 = genB.generateTray(board, 200);

      expect(trayA2.map((p) => p.id), equals(trayB2.map((p) => p.id)));
    });
  });
}
