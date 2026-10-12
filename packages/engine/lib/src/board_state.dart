import 'layout.dart';
import 'tile.dart';

/// Faces and presence of every slot in a layout. Pure rules, no history.
class BoardState {
  final Layout layout;
  final List<int> faces;
  final List<bool> present;

  BoardState(this.layout, List<int> faces)
    : faces = List.of(faces),
      present = List.filled(layout.length, true) {
    if (faces.length != layout.length) {
      throw ArgumentError('faces length ${faces.length} != ${layout.length}');
    }
  }

  BoardState.copy(BoardState other)
    : layout = other.layout,
      faces = List.of(other.faces),
      present = List.of(other.present);

  int get remaining => present.where((p) => p).length;
  bool get isCleared => remaining == 0;

  bool _anyPresent(List<int> idx) {
    for (final j in idx) {
      if (present[j]) return true;
    }
    return false;
  }

  bool isFree(int i) {
    if (!present[i]) return false;
    if (_anyPresent(layout.above[i])) return false;
    return !_anyPresent(layout.left[i]) || !_anyPresent(layout.right[i]);
  }

  List<int> freeTiles() => [
    for (var i = 0; i < layout.length; i++)
      if (isFree(i)) i,
  ];

  /// Null if legal, otherwise the reason.
  String? whyIllegal(int a, int b) {
    final n = layout.length;
    if (a < 0 || a >= n || b < 0 || b >= n) return 'tile index out of range';
    if (a == b) return 'a tile cannot match itself';
    if (!present[a] || !present[b]) return 'tile already removed';
    if (!isFree(a) || !isFree(b)) return 'tile is not free';
    if (!Faces.matches(faces[a], faces[b])) return 'faces do not match';
    return null;
  }

  bool isLegal(int a, int b) => whyIllegal(a, b) == null;

  /// All legal pairs (a < b) in ascending order.
  List<(int, int)> legalPairs() {
    final free = freeTiles();
    final pairs = <(int, int)>[];
    for (var i = 0; i < free.length; i++) {
      for (var j = i + 1; j < free.length; j++) {
        if (Faces.matches(faces[free[i]], faces[free[j]])) {
          pairs.add((free[i], free[j]));
        }
      }
    }
    return pairs;
  }

  bool get isDeadEnd => !isCleared && legalPairs().isEmpty;

  void remove(int a, int b) {
    present[a] = false;
    present[b] = false;
  }

  void restore(int a, int b) {
    present[a] = true;
    present[b] = true;
  }
}
