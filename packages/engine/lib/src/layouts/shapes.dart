import '../layout.dart';

/// Builder for layouts on the half-tile grid: one grid step is half a tile,
/// so `x = 2 * column` and odd values straddle two tiles below.
class _B {
  final List<Position> p = [];

  /// [cols] x [rows] tiles with the top-left tile at (x, y) on layer z.
  void block(int x, int y, int cols, int rows, int z) {
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        p.add(Position(x + 2 * c, y + 2 * r, z));
      }
    }
  }
}

Layout _make(String id, String name, void Function(_B) build) {
  final b = _B();
  build(b);
  return Layout(id, name, b.p);
}

/// 20-tile first-launch board.
Layout buildTutorial() => _make('tutorial', 'Tutorial', (b) {
  b.block(0, 0, 4, 4, 0);
  b.block(2, 2, 2, 2, 1);
});

/// Square: 80 + 48 + 16.
Layout buildFortress() => _make('fortress', 'Fortress', (b) {
  b.block(0, 0, 10, 8, 0);
  b.block(2, 2, 8, 6, 1);
  b.block(6, 4, 4, 4, 2);
});

/// Portrait: 80 + 48 + 16.
Layout buildKeep() => _make('keep', 'Keep', (b) {
  b.block(0, 0, 8, 10, 0);
  b.block(2, 2, 6, 8, 1);
  b.block(4, 6, 4, 4, 2);
});

/// Portrait: 84 + 50 + 10, with a straddling ridge on top.
Layout buildTower() => _make('tower', 'Tower', (b) {
  b.block(0, 0, 7, 12, 0);
  b.block(2, 2, 5, 10, 1);
  b.block(5, 7, 2, 5, 2);
});

/// Portrait plus shape: 80 + 40 + 24.
Layout buildCross() => _make('cross', 'Cross', (b) {
  b.block(8, 0, 4, 12, 0);
  b.block(0, 8, 4, 4, 0);
  b.block(16, 8, 4, 4, 0);
  b.block(8, 2, 4, 10, 1);
  b.block(8, 6, 4, 6, 2);
});

/// Wide-ish: 84 + 50 + 10.
Layout buildPyramid() => _make('pyramid', 'Pyramid', (b) {
  b.block(0, 0, 12, 7, 0);
  b.block(2, 2, 10, 5, 1);
  b.block(7, 5, 5, 2, 2);
});

/// Portrait: two towers joined by a span. 80 + 64.
Layout buildBridge() => _make('bridge', 'Bridge', (b) {
  b.block(0, 0, 3, 12, 0);
  b.block(10, 0, 3, 12, 0);
  b.block(6, 8, 2, 4, 0);
  b.block(0, 2, 3, 10, 1);
  b.block(10, 2, 3, 10, 1);
  b.block(6, 10, 2, 2, 1);
});

/// Landscape: rising steps. 72 + 54 + 18.
Layout buildStairs() => _make('stairs', 'Stairs', (b) {
  b.block(0, 0, 12, 6, 0);
  b.block(6, 0, 9, 6, 1);
  b.block(18, 0, 3, 6, 2);
});

/// Landscape: two summits. 84 + 40 + 12 + 8.
Layout buildTwinPeaks() => _make('twin_peaks', 'Twin Peaks', (b) {
  b.block(0, 0, 14, 6, 0);
  b.block(2, 2, 5, 4, 1);
  b.block(16, 2, 5, 4, 1);
  b.block(4, 4, 3, 2, 2);
  b.block(18, 4, 3, 2, 2);
  b.block(4, 4, 2, 2, 3);
  b.block(18, 4, 2, 2, 3);
});

/// Portrait: 88 + 54 + 2.
Layout buildLantern() => _make('lantern', 'Lantern', (b) {
  b.block(0, 0, 8, 11, 0);
  b.block(2, 2, 6, 9, 1);
  b.block(6, 10, 2, 1, 2);
});

/// A ring two layers high with corner turrets. 64 + 64 + 16.
Layout buildArena() => _make('arena', 'Arena', (b) {
  for (final z in [0, 1]) {
    b.block(0, 0, 12, 2, z);
    b.block(0, 12, 12, 2, z);
    b.block(0, 4, 2, 4, z);
    b.block(20, 4, 2, 4, z);
  }
  for (final (x, y) in [(0, 0), (20, 0), (0, 12), (20, 12)]) {
    b.block(x, y, 2, 2, 2);
  }
});

// Short boards (72-100 tiles): commute-length sessions and more natural
// between-board breaks.

/// 48 + 24.
Layout buildGarden() => _make('garden', 'Garden', (b) {
  b.block(0, 0, 8, 6, 0);
  b.block(2, 2, 6, 4, 1);
});

/// Portrait: 50 + 24 + 10.
Layout buildSpire() => _make('spire', 'Spire', (b) {
  b.block(0, 0, 5, 10, 0);
  b.block(2, 2, 3, 8, 1);
  b.block(3, 4, 2, 5, 2);
});

/// Portrait: 56 + 30 + 2.
Layout buildMeadow() => _make('meadow', 'Meadow', (b) {
  b.block(0, 0, 7, 8, 0);
  b.block(2, 2, 5, 6, 1);
  b.block(6, 6, 1, 2, 2);
});

/// 64 + 24 + 8 + 4.
Layout buildPagoda() => _make('pagoda', 'Pagoda', (b) {
  b.block(0, 0, 8, 8, 0);
  b.block(2, 4, 6, 4, 1);
  b.block(4, 6, 4, 2, 2);
  b.block(6, 6, 2, 2, 3);
});
