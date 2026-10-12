import 'package:mahjong_engine/mahjong_engine.dart';

void main(List<String> args) {
  final n = args.isEmpty ? 200 : int.parse(args.first);
  final layout = layoutById('turtle');
  final sw = Stopwatch()..start();
  for (var s = 0; s < n; s++) {
    generateDeal(layout, s);
  }
  print(
    '$n deals in ${sw.elapsedMilliseconds} ms '
    '(${(sw.elapsedMicroseconds / n / 1000).toStringAsFixed(2)} ms/deal)',
  );
}
