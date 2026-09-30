/// Deterministic 32-bit stateful Pseudo-Random Number Generator (Mulberry32).
/// Guarantees identical sequence across 32/64-bit platforms, Web, Android, iOS.
/// Pure Dart class with zero Flutter dependencies.
class Mulberry32 {
  int _state;

  Mulberry32([int seed = 0]) : _state = seed & 0xFFFFFFFF;

  int get state => _state;

  void reseed(int seed) {
    _state = seed & 0xFFFFFFFF;
  }

  /// Generates the next pseudo-random unsigned 32-bit integer [0, 4294967295].
  int nextUint32() {
    _state = (_state + 0x6D2B79F5) & 0xFFFFFFFF;
    int z = _state;
    z = ((z ^ (z >> 15)) * (z | 1)) & 0xFFFFFFFF;
    z ^= (z + (((z ^ (z >> 7)) * (z | 61)) & 0xFFFFFFFF)) & 0xFFFFFFFF;
    return (z ^ (z >> 14)) & 0xFFFFFFFF;
  }

  /// Returns a pseudo-random double in the range [0.0, 1.0).
  double nextDouble() {
    return nextUint32() / 4294967296.0;
  }

  /// Returns a pseudo-random integer in the range [min, max] inclusive.
  int nextInt(int min, int max) {
    assert(max >= min, 'max must be greater than or equal to min');
    final range = (max - min) + 1;
    return min + (nextUint32() % range);
  }
}
