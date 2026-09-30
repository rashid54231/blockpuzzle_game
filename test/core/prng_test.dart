import 'package:flutter_test/flutter_test.dart';
import 'package:blockpuzzle_game/core/generator/prng.dart';

void main() {
  group('Mulberry32 PRNG Determinism Tests', () {
    test('Identical seeds produce identical sequence', () {
      const seed = 987654321;
      final rngA = Mulberry32(seed);
      final rngB = Mulberry32(seed);

      final sequenceA = List.generate(50, (_) => rngA.nextUint32());
      final sequenceB = List.generate(50, (_) => rngB.nextUint32());

      expect(sequenceA, equals(sequenceB));
    });

    test('Different seeds produce different sequences', () {
      final rngA = Mulberry32(1111);
      final rngB = Mulberry32(2222);

      final valA = rngA.nextUint32();
      final valB = rngB.nextUint32();

      expect(valA, isNot(equals(valB)));
    });

    test('nextDouble returns values within [0.0, 1.0)', () {
      final rng = Mulberry32(42);
      for (int i = 0; i < 100; i++) {
        final val = rng.nextDouble();
        expect(val, greaterThanOrEqualTo(0.0));
        expect(val, lessThan(1.0));
      }
    });

    test('nextInt generates integers within inclusive bounds', () {
      final rng = Mulberry32(777);
      for (int i = 0; i < 200; i++) {
        final val = rng.nextInt(3, 7);
        expect(val, greaterThanOrEqualTo(3));
        expect(val, lessThanOrEqualTo(7));
      }
    });
  });
}
