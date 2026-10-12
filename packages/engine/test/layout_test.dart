import 'package:mahjong_engine/mahjong_engine.dart';
import 'package:test/test.dart';

void main() {
  for (final id in layoutIds) {
    test('layout $id is valid', () {
      expect(layoutById(id).validate(), isEmpty);
    });
  }

  test('turtle has the classic layer counts', () {
    final l = layoutById('turtle');
    final counts = <int, int>{};
    for (final p in l.positions) {
      counts[p.z] = (counts[p.z] ?? 0) + 1;
    }
    expect(counts, {0: 87, 1: 36, 2: 16, 3: 4, 4: 1});
  });

  test('turtle end tile blocks both rows it touches', () {
    final l = layoutById('turtle');
    final leftEnd = l.positions.indexWhere((p) => p.x == 0 && p.z == 0);
    expect(l.right[leftEnd].length, 2);
  });
}
