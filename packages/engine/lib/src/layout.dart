/// A tile slot on the half-tile grid. A tile at (x, y, z) covers cells
/// x..x+1 and y..y+1 on layer z.
class Position {
  final int x, y, z;
  const Position(this.x, this.y, this.z);

  List<int> toJson() => [x, y, z];

  @override
  String toString() => '($x,$y,$z)';
}

/// An immutable board shape with precomputed neighbour relations.
///
/// Rules (rule set v1):
/// - `above[i]`: positions on layer z+1 whose footprint overlaps i.
/// - `below[i]`: positions on layer z-1 whose footprint overlaps i.
/// - `left[i]` / `right[i]`: positions on the same layer at x-2 / x+2 whose
///   rows overlap (|dy| < 2).
/// - A present tile is free iff no present tile is above it and it has no
///   present tile on its left or none on its right.
class Layout {
  final String id;
  final String name;
  final List<Position> positions;
  late final List<List<int>> above, below, left, right;

  Layout(this.id, this.name, List<Position> positions)
    : positions = List.unmodifiable(positions) {
    final n = positions.length;
    above = List.generate(n, (_) => <int>[]);
    below = List.generate(n, (_) => <int>[]);
    left = List.generate(n, (_) => <int>[]);
    right = List.generate(n, (_) => <int>[]);
    for (var i = 0; i < n; i++) {
      final p = positions[i];
      for (var j = 0; j < n; j++) {
        if (i == j) continue;
        final q = positions[j];
        final dx = q.x - p.x, dy = q.y - p.y;
        final overlap = dx.abs() < 2 && dy.abs() < 2;
        if (q.z == p.z + 1 && overlap) above[i].add(j);
        if (q.z == p.z - 1 && overlap) below[i].add(j);
        if (q.z == p.z && dy.abs() < 2) {
          if (dx == -2) left[i].add(j);
          if (dx == 2) right[i].add(j);
        }
      }
    }
  }

  int get length => positions.length;

  /// Returns a list of problems; empty means the layout is valid.
  List<String> validate() {
    final problems = <String>[];
    if (length == 0 || length.isOdd || length > 144) {
      problems.add('need an even number of positions up to 144, got $length');
    }
    for (var i = 0; i < length; i++) {
      final p = positions[i];
      for (var j = i + 1; j < length; j++) {
        final q = positions[j];
        if (p.z == q.z && (p.x - q.x).abs() < 2 && (p.y - q.y).abs() < 2) {
          problems.add('positions $i $p and $j $q overlap');
        }
      }
      if (p.z > 0 && below[i].isEmpty) {
        problems.add('position $i $p floats with nothing beneath');
      }
    }
    return problems;
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'positions': [for (final p in positions) p.toJson()],
  };
}
