import 'package:mahjong_engine/mahjong_engine.dart';

// Prints size, validity and deal speed for every layout.
void main() {
  for (final id in layoutIds) {
    final l = layoutById(id);
    final problems = l.validate();
    final xs = l.positions.map((p) => p.x), ys = l.positions.map((p) => p.y);
    final cols = (xs.reduce((a, b) => a > b ? a : b) + 2) / 2;
    final rows = (ys.reduce((a, b) => a > b ? a : b) + 2) / 2;
    var line =
        '${id.padRight(11)} n=${l.length} ${cols}x$rows '
        'aspect(h/w)=${(rows * 4 / 3 / cols).toStringAsFixed(2)}';
    if (problems.isNotEmpty) {
      print('$line INVALID: ${problems.take(3)}');
      continue;
    }
    final sw = Stopwatch()..start();
    var failed = 0;
    for (var s = 0; s < 30; s++) {
      try {
        generateDeal(l, s);
      } on StateError {
        failed++;
      }
    }
    line += ' ${(sw.elapsedMilliseconds / 30).toStringAsFixed(0)}ms/deal';
    print(failed > 0 ? '$line FAILED $failed/30' : line);
  }
}
