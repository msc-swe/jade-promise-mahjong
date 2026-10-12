/// Tile faces, ids 0..41:
///   0-8   dots 1-9        9-17  bamboo 1-9      18-26 characters 1-9
///   27-30 winds E,S,W,N   31-33 dragons red, green, white
///   34-37 flowers 1-4     38-41 seasons 1-4
/// A full set has four copies of faces 0..33 and one of each of 34..41.
abstract final class Faces {
  static const int count = 42;
  static const int flowerStart = 34;
  static const int seasonStart = 38;

  /// Two faces match iff their match classes are equal. Any flower matches
  /// any flower and any season matches any season.
  static int matchClass(int face) {
    if (face < flowerStart) return face;
    if (face < seasonStart) return flowerStart;
    return flowerStart + 1;
  }

  static bool matches(int a, int b) => matchClass(a) == matchClass(b);

  /// The 144-tile multiset grouped into 72 matching pairs, in canonical
  /// order: each of faces 0..33 twice as (f, f), then flowers (34,35),(36,37),
  /// then seasons (38,39),(40,41).
  static List<(int, int)> fullSetPairs() => [
    for (var f = 0; f < flowerStart; f++) ...[(f, f), (f, f)],
    (34, 35),
    (36, 37),
    (38, 39),
    (40, 41),
  ];

  static String debugName(int face) {
    if (face < 27) {
      const suits = ['D', 'B', 'C'];
      return '${suits[face ~/ 9]}${face % 9 + 1}';
    }
    const names = [
      'WE', 'WS', 'WW', 'WN', 'DR', 'DG', 'DW', //
      'F1', 'F2', 'F3', 'F4', 'S1', 'S2', 'S3', 'S4',
    ];
    return names[face - 27];
  }
}
