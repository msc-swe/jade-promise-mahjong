import 'board_state.dart';
import 'layout.dart';
import 'rng_pcg32.dart';
import 'tile.dart';

/// Generator version 1. Changing anything in this file changes deals, so a
/// change requires a new [generatorVersion] while v1 stays available for old
/// certificates.
const int generatorVersion = 1;
const int maxPlacementAttempts = 2000;

/// Reverse-play placement over [subset] (which must be closed downward: if a
/// slot is in it, every slot beneath it is too).
///
/// Each step lists every pair (a < b) of unplaced slots such that, with
/// S = slots placed so far:
///  1. every slot beneath a and b is in S,
///  2. a and b are both free in S ∪ {a, b},
///  3. no left/right chain of unplaced slots starting next to a or b runs
///     into another placed tile (the last slot filled in such a gap would
///     have tiles on both sides and could never be free).
/// One pair is chosen with `rng.nextBounded(count)`. If none qualify the
/// attempt restarts from empty with the same, continuing RNG stream.
///
/// Returns the placement order; removing pairs in reverse order clears the
/// subset. Returns null if every attempt fails.
List<(int, int)>? placeReverse(Layout layout, List<int> subset, Pcg32 rng) {
  final n = layout.length;
  final inSubset = List.filled(n, false);
  for (final i in subset) {
    inSubset[i] = true;
  }
  final sorted = List.of(subset)..sort();

  for (var attempt = 0; attempt < maxPlacementAttempts; attempt++) {
    final placed = List.filled(n, false);
    final order = <(int, int)>[];
    var ok = true;

    bool anyPlaced(List<int> idx) {
      for (final j in idx) {
        if (placed[j]) return true;
      }
      return false;
    }

    bool freeNow(int i) =>
        !anyPlaced(layout.above[i]) &&
        (!anyPlaced(layout.left[i]) || !anyPlaced(layout.right[i]));

    // Walks from s in one direction through unplaced subset slots; true if
    // the walk reaches another placed tile (a gap that can never be filled).
    bool gapFrom(int s, List<List<int>> dir) {
      final seen = <int>{};
      final stack = [
        for (final u in dir[s])
          if (inSubset[u] && !placed[u]) u,
      ];
      while (stack.isNotEmpty) {
        final u = stack.removeLast();
        if (!seen.add(u)) continue;
        for (final v in dir[u]) {
          if (!inSubset[v]) continue;
          if (placed[v]) return true;
          stack.add(v);
        }
      }
      return false;
    }

    bool dooms(int a, int b) =>
        gapFrom(a, layout.left) ||
        gapFrom(a, layout.right) ||
        gapFrom(b, layout.left) ||
        gapFrom(b, layout.right);

    while (order.length * 2 < sorted.length) {
      final candidates = <int>[];
      for (final i in sorted) {
        if (placed[i]) continue;
        if (layout.below[i].any((j) => inSubset[j] && !placed[j])) continue;
        if (!freeNow(i)) continue;
        candidates.add(i);
      }
      final valid = <(int, int)>[];
      for (var x = 0; x < candidates.length; x++) {
        for (var y = x + 1; y < candidates.length; y++) {
          final a = candidates[x], b = candidates[y];
          placed[a] = true;
          placed[b] = true;
          if (freeNow(a) && freeNow(b) && !dooms(a, b)) valid.add((a, b));
          placed[a] = false;
          placed[b] = false;
        }
      }
      if (valid.isEmpty) {
        ok = false;
        break;
      }
      final pick = valid[rng.nextBounded(valid.length)];
      placed[pick.$1] = true;
      placed[pick.$2] = true;
      order.add(pick);
    }
    if (ok) return order;
  }
  return null;
}

class Deal {
  final Layout layout;
  final int seed;
  final List<int> faces;

  /// A complete clearing sequence (reverse of the placement order).
  final List<(int, int)> solution;

  Deal(this.layout, this.seed, this.faces, this.solution);

  BoardState toBoard() => BoardState(layout, faces);
}

void _assign(
  List<int> faces,
  List<(int, int)> placement,
  List<(int, int)> facePairs,
) {
  for (var k = 0; k < placement.length; k++) {
    faces[placement[k].$1] = facePairs[k].$1;
    faces[placement[k].$2] = facePairs[k].$2;
  }
}

/// Deterministic deal: RNG stream `Pcg32(seed, 0)`; placement first, then a
/// Fisher–Yates shuffle of [Faces.fullSetPairs] assigned to placement pairs in
/// order. Layouts with fewer than 144 slots use the first n/2 shuffled pairs.
Deal generateDeal(Layout layout, int seed) {
  final rng = Pcg32(seed, 0);
  final all = List.generate(layout.length, (i) => i);
  final placement = placeReverse(layout, all, rng);
  if (placement == null) {
    throw StateError('layout ${layout.id} could not be dealt (seed $seed)');
  }
  final pairs = Faces.fullSetPairs();
  rng.shuffle(pairs);
  final faces = List.filled(layout.length, -1);
  _assign(faces, placement, pairs);
  return Deal(layout, seed, faces, placement.reversed.toList());
}

/// Solvable reshuffle of the tiles still on [board]. RNG stream
/// `Pcg32(seed, shuffleIndex + 1)`. Remaining faces are paired by grouping on
/// match class and pairing in ascending face order, then shuffled and
/// assigned to a reverse-play placement of the remaining slots.
///
/// Returns a clearing order for the new arrangement, or null (leaving the
/// board untouched) when none was found, e.g. two tiles stacked directly on
/// each other.
List<(int, int)>? reshuffle(BoardState board, int seed, int shuffleIndex) {
  final rng = Pcg32(seed, shuffleIndex + 1);
  final remaining = [
    for (var i = 0; i < board.layout.length; i++)
      if (board.present[i]) i,
  ];
  final placement = placeReverse(board.layout, remaining, rng);
  if (placement == null) return null;
  final byClass = <int, List<int>>{};
  for (final i in remaining) {
    byClass
        .putIfAbsent(Faces.matchClass(board.faces[i]), () => [])
        .add(board.faces[i]);
  }
  final pairs = <(int, int)>[];
  for (final cls in byClass.keys.toList()..sort()) {
    final fs = byClass[cls]!..sort();
    for (var k = 0; k + 1 < fs.length; k += 2) {
      pairs.add((fs[k], fs[k + 1]));
    }
  }
  rng.shuffle(pairs);
  _assign(board.faces, placement, pairs);
  return placement.reversed.toList();
}
