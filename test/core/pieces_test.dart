import 'package:flutter_test/flutter_test.dart';
import 'package:blockpuzzle_game/core/pieces/piece_catalog.dart';

void main() {
  group('Piece Catalog Tests', () {
    test('Catalog contains at least 24 unique unrotatable shapes', () {
      expect(PieceCatalog.all.length, greaterThanOrEqualTo(24));
      final ids = PieceCatalog.all.map((p) => p.id).toSet();
      expect(ids.length, equals(PieceCatalog.all.length));
    });

    test('Pieces have valid dimensions and point bounds', () {
      for (final piece in PieceCatalog.all) {
        expect(piece.cellCount, greaterThan(0));
        expect(piece.width, greaterThan(0));
        expect(piece.height, greaterThan(0));
        expect(piece.width, lessThanOrEqualTo(5));
        expect(piece.height, lessThanOrEqualTo(5));

        for (final p in piece.points) {
          expect(p.x, greaterThanOrEqualTo(0));
          expect(p.x, lessThan(piece.width));
          expect(p.y, greaterThanOrEqualTo(0));
          expect(p.y, lessThan(piece.height));
        }
      }
    });

    test('All piece shapes have colorblind accessibility marks', () {
      for (final piece in PieceCatalog.all) {
        expect(piece.shapeMark, isNotEmpty);
      }
    });

    test('getById returns matching shape or null', () {
      expect(PieceCatalog.getById(1)?.name, equals('Single Dot'));
      expect(PieceCatalog.getById(9999), isNull);
    });
  });
}
