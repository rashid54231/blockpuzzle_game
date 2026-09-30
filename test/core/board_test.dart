import 'package:flutter_test/flutter_test.dart';
import 'package:blockpuzzle_game/core/board/board.dart';
import 'package:blockpuzzle_game/core/board/board_point.dart';
import 'package:blockpuzzle_game/core/pieces/piece_catalog.dart';

void main() {
  group('Board Model Tests', () {
    test('Initial board is completely empty', () {
      final board = Board();
      expect(board.isEmpty, isTrue);
      expect(board.filledCellCount, equals(0));
      expect(board.isFull, isFalse);
    });

    test('Valid placement updates filled cells correctly', () {
      final board = Board();
      final piece = PieceCatalog.square2; // 2x2 = 4 cells
      expect(board.canPlacePiece(piece, const BoardPoint(0, 0)), isTrue);

      final updatedBoard = board.placePiece(piece, const BoardPoint(0, 0), 1);
      expect(updatedBoard.filledCellCount, equals(4));
      expect(updatedBoard.isCellEmpty(0, 0), isFalse);
      expect(updatedBoard.isCellEmpty(1, 1), isFalse);
      expect(updatedBoard.isCellEmpty(2, 2), isTrue);
    });

    test('Out of bounds placement is rejected', () {
      final board = Board();
      final piece = PieceCatalog.square2;
      expect(board.canPlacePiece(piece, const BoardPoint(7, 7)), isFalse);
      expect(board.canPlacePiece(piece, const BoardPoint(-1, 0)), isFalse);
    });

    test('Overlapping placement is rejected', () {
      final board = Board();
      final piece = PieceCatalog.dot;
      final board1 = board.placePiece(piece, const BoardPoint(3, 3), 1);
      expect(board1.canPlacePiece(piece, const BoardPoint(3, 3)), isFalse);
    });

    test('Simultaneous row and column clearing', () {
      var board = Board();

      // Fill entire row 0 except cell (0, 0)
      for (int x = 1; x < 8; x++) {
        board = board.placePiece(PieceCatalog.dot, BoardPoint(x, 0), 1);
      }

      // Fill entire column 0 except cell (0, 0)
      for (int y = 1; y < 8; y++) {
        board = board.placePiece(PieceCatalog.dot, BoardPoint(0, y), 2);
      }

      // Place single dot at (0, 0) to simultaneously fill row 0 and column 0
      final completedBoard = board.placePiece(
        PieceCatalog.dot,
        const BoardPoint(0, 0),
        3,
      );
      final lines = completedBoard.findFilledLines();

      expect(lines.rows, equals([0]));
      expect(lines.columns, equals([0]));
      expect(lines.totalLines, equals(2));

      // Clear both lines
      final clearedBoard = completedBoard.clearLines(lines);
      expect(clearedBoard.isEmpty, isTrue);
    });

    test('Preview cleared lines predicts clearing correctly', () {
      var board = Board();
      for (int x = 0; x < 7; x++) {
        board = board.placePiece(PieceCatalog.dot, BoardPoint(x, 4), 1);
      }
      final preview = board.previewClearedLines(
        PieceCatalog.dot,
        const BoardPoint(7, 4),
      );
      expect(preview.rows, equals([4]));
    });

    test('Revive clear area clears center 4x4 area', () {
      var board = Board();
      for (int y = 0; y < 8; y++) {
        for (int x = 0; x < 8; x++) {
          board = board.placePiece(PieceCatalog.dot, BoardPoint(x, y), 1);
        }
      }
      expect(board.isFull, isTrue);

      final revived = board.clearReviveArea();
      expect(revived.isCellEmpty(2, 2), isTrue);
      expect(revived.isCellEmpty(3, 3), isTrue);
      expect(revived.isCellEmpty(0, 0), isFalse);
      expect(revived.filledCellCount, equals(64 - 16));
    });
  });
}
