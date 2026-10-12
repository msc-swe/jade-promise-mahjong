import 'board_state.dart';
import 'canonical.dart';
import 'certificate.dart';
import 'generator.dart';
import 'layouts/registry.dart';

/// Live game: incremental state plus the move log. The certificate check
/// does NOT reuse this class; see `replay.dart`.
class Game {
  final int seed;
  final Deal deal;
  final BoardState board;
  final List<Move> _log = [];
  final List<(int, int)> _undoStack = [];
  int _shuffles = 0;

  Game._(this.seed, this.deal) : board = deal.toBoard();

  factory Game.start(String layoutId, int seed) =>
      Game._(seed, generateDeal(layoutById(layoutId), seed));

  /// Rebuilds a saved game by re-applying its move log. Returns null if the
  /// log does not apply cleanly (e.g. it came from another engine version).
  static Game? restore(String layoutId, int seed, List<Move> moves) {
    final Game g;
    try {
      g = Game.start(layoutId, seed);
    } on ArgumentError {
      return null;
    }
    for (final m in moves) {
      final ok = switch (m.t) {
        MoveType.pair => m.a != null && m.b != null && g.matchPair(m.a!, m.b!),
        MoveType.undo => g.undo(),
        MoveType.hint => g.hint() != null,
        MoveType.shuffle => g.shuffle(),
      };
      if (!ok) return null;
    }
    return g;
  }

  List<Move> get moves => List.unmodifiable(_log);
  int count(MoveType t) => _log.where((m) => m.t == t).length;
  int get shuffleCount => _shuffles;
  bool get canUndo => _undoStack.isNotEmpty;
  bool get isWon => board.isCleared;
  bool get isDeadEnd => board.isDeadEnd;

  void _record(MoveType t, [int? a, int? b]) =>
      _log.add(Move(_log.length, t, a, b));

  bool matchPair(int a, int b) {
    if (!board.isLegal(a, b)) return false;
    board.remove(a, b);
    _undoStack.add((a, b));
    _record(MoveType.pair, a, b);
    return true;
  }

  /// Undo never crosses a shuffle.
  bool undo() {
    if (_undoStack.isEmpty) return false;
    final (a, b) = _undoStack.removeLast();
    board.restore(a, b);
    _record(MoveType.undo);
    return true;
  }

  (int, int)? hint() {
    final pairs = board.legalPairs();
    if (pairs.isEmpty) return null;
    final p = pairs.first;
    _record(MoveType.hint, p.$1, p.$2);
    return p;
  }

  /// Solvable reshuffle; allowed at any time (voluntary or forced). The
  /// verifier reports which shuffles happened in a genuine dead end.
  bool shuffle() {
    if (board.isCleared) return false;
    if (reshuffle(board, seed, _shuffles) == null) return false;
    _shuffles++;
    _undoStack.clear();
    _record(MoveType.shuffle);
    return true;
  }

  Certificate certificate({required String clientBuild, DateTime? now}) =>
      Certificate(
        kind: board.isCleared ? CertificateKind.win : CertificateKind.deadEnd,
        seed: seed,
        layoutId: deal.layout.id,
        generator: generatorVersion,
        moves: moves,
        finalStateHash: stateHash(board),
        freeTileIdx: board.freeTiles(),
        clientBuild: clientBuild,
        createdAt: now ?? DateTime.now(),
      );
}
