import 'package:mahjong_engine/mahjong_engine.dart';
import 'package:test/test.dart';

void main() {
  test('PCG32 matches the reference pcg32-demo (seed 42, seq 54)', () {
    final rng = Pcg32(42, 54);
    final out = List.generate(6, (_) => rng.nextUint32());
    expect(out, [
      0xa15c02b7, 0x7b47f409, 0xba1d3330, //
      0x83d2f293, 0xbfa4784b, 0xcbed606e,
    ]);
  });

  test('nextBounded stays in range and covers it', () {
    final rng = Pcg32(1, 1);
    final seen = <int>{};
    for (var i = 0; i < 1000; i++) {
      final v = rng.nextBounded(7);
      expect(v, inInclusiveRange(0, 6));
      seen.add(v);
    }
    expect(seen.length, 7);
  });

  test('seed string round trip keeps all 64 bits', () {
    for (final s in [
      '0',
      '42',
      '9223372036854775808',
      '18446744073709551615',
    ]) {
      expect(formatSeed(parseSeed(s)), s);
    }
  });

  test('daily seed is stable per UTC date', () {
    final a = dailySeed(DateTime.utc(2026, 10, 5, 0, 1));
    final b = dailySeed(DateTime.utc(2026, 10, 5, 23, 59));
    final c = dailySeed(DateTime.utc(2026, 10, 6));
    expect(a, b);
    expect(a, isNot(c));
  });
}
