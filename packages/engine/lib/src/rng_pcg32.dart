/// PCG32 (pcg32_random_r / XSH-RR 64/32) exactly as in the PCG reference
/// implementation by M. E. O'Neill. Dart native ints are 64-bit two's
/// complement with wrapping arithmetic, so the 64-bit state math is exact.
///
/// This algorithm is part of the published rule set: any reimplementation
/// (e.g. the Phase 2 C# verifier) must reproduce it bit for bit.
class Pcg32 {
  static const int _multiplier = 6364136223846793005;

  int _state = 0;
  final int _inc;

  /// Equivalent to `pcg32_srandom_r(rng, initState, initSeq)`.
  Pcg32(int initState, int initSeq) : _inc = (initSeq << 1) | 1 {
    _step();
    _state += initState;
    _step();
  }

  void _step() {
    _state = _state * _multiplier + _inc;
  }

  /// Next uniformly distributed unsigned 32-bit value.
  int nextUint32() {
    final old = _state;
    _step();
    final xorShifted = (((old >>> 18) ^ old) >>> 27) & 0xFFFFFFFF;
    final rot = old >>> 59;
    return ((xorShifted >>> rot) | (xorShifted << ((-rot) & 31))) & 0xFFFFFFFF;
  }

  /// Unbiased value in `[0, bound)`, `pcg32_boundedrand_r` rejection method:
  /// threshold = (2^32 - bound) mod bound; draw until r >= threshold.
  int nextBounded(int bound) {
    if (bound <= 0 || bound > 0xFFFFFFFF) {
      throw ArgumentError.value(bound, 'bound', 'must be in 1..2^32-1');
    }
    final threshold = (0x100000000 - bound) % bound;
    while (true) {
      final r = nextUint32();
      if (r >= threshold) return r % bound;
    }
  }

  /// In-place Fisher–Yates: for i from n-1 down to 1, swap i with
  /// nextBounded(i + 1).
  void shuffle<T>(List<T> list) {
    for (var i = list.length - 1; i > 0; i--) {
      final j = nextBounded(i + 1);
      final tmp = list[i];
      list[i] = list[j];
      list[j] = tmp;
    }
  }
}
