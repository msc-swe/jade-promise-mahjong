import '../layout.dart';

/// The traditional Turtle shape (87 + 36 + 16 + 4 + 1 tiles), drawn from
/// scratch on the half-tile grid.
Layout buildTurtle() {
  final p = <Position>[];
  void row(int y, int fromCol, int toCol, int z) {
    for (var c = fromCol; c <= toCol; c++) {
      p.add(Position(c * 2, y * 2, z));
    }
  }

  // Layer 0: rows of 12, 8, 10, 12, 12, 10, 8, 12 plus three end tiles.
  row(0, 1, 12, 0);
  row(1, 3, 10, 0);
  row(2, 2, 11, 0);
  row(3, 1, 12, 0);
  row(4, 1, 12, 0);
  row(5, 2, 11, 0);
  row(6, 3, 10, 0);
  row(7, 1, 12, 0);
  p.add(const Position(0, 7, 0));
  p.add(const Position(26, 7, 0));
  p.add(const Position(28, 7, 0));
  // Layers 1-3: centred 6x6, 4x4, 2x2 squares.
  for (var r = 1; r <= 6; r++) {
    row(r, 4, 9, 1);
  }
  for (var r = 2; r <= 5; r++) {
    row(r, 5, 8, 2);
  }
  for (var r = 3; r <= 4; r++) {
    row(r, 6, 7, 3);
  }
  // Cap tile straddling the 2x2.
  p.add(const Position(13, 7, 4));
  return Layout('turtle', 'Turtle', p);
}
