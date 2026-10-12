import 'canonical.dart';
import 'certificate.dart';
import 'generator.dart';
import 'layout.dart';
import 'layouts/registry.dart';

class VerificationResult {
  final bool ok;
  final String? error;

  /// Move numbers of shuffles that happened with no legal pair on the board.
  final List<int> forcedShuffles;
  final List<int> voluntaryShuffles;

  const VerificationResult._(
    this.ok,
    this.error,
    this.forcedShuffles,
    this.voluntaryShuffles,
  );

  factory VerificationResult.fail(String error) =>
      VerificationResult._(false, error, const [], const []);

  @override
  String toString() => ok ? 'OK' : 'REJECTED: $error';
}

/// Independent check of a certificate: rebuilds everything from the seed,
/// sharing only the rule primitives with live play.
VerificationResult verifyCertificate(Certificate c) {
  if (c.version != certificateVersion) {
    return VerificationResult.fail('unsupported certificate version');
  }
  if (c.ruleSet != ruleSetVersion) {
    return VerificationResult.fail('unsupported rule set ${c.ruleSet}');
  }
  if (c.generator != generatorVersion) {
    return VerificationResult.fail('unsupported generator ${c.generator}');
  }
  if (c.moves.length > maxCertificateMoves) {
    return VerificationResult.fail('too many moves');
  }
  final Layout layout;
  try {
    layout = layoutById(c.layoutId);
  } on ArgumentError {
    return VerificationResult.fail('unknown layout ${c.layoutId}');
  }

  // 1. The deal must be solvable: its constructive solution clears it.
  final deal = generateDeal(layout, c.seed);
  final proof = deal.toBoard();
  for (final (a, b) in deal.solution) {
    final why = proof.whyIllegal(a, b);
    if (why != null) return VerificationResult.fail('deal not solvable: $why');
    proof.remove(a, b);
  }
  if (!proof.isCleared) return VerificationResult.fail('deal not solvable');

  // 2. Every logged move must be legal.
  final board = deal.toBoard();
  final undo = <(int, int)>[];
  final forced = <int>[], voluntary = <int>[];
  var shuffles = 0;
  for (var k = 0; k < c.moves.length; k++) {
    final m = c.moves[k];
    if (m.n != k) return VerificationResult.fail('move $k has sequence ${m.n}');
    switch (m.t) {
      case MoveType.pair:
        if (m.a == null || m.b == null) {
          return VerificationResult.fail('move $k: pair without tiles');
        }
        final why = board.whyIllegal(m.a!, m.b!);
        if (why != null) return VerificationResult.fail('move $k: $why');
        board.remove(m.a!, m.b!);
        undo.add((m.a!, m.b!));
      case MoveType.undo:
        if (undo.isEmpty) return VerificationResult.fail('move $k: no undo');
        final (a, b) = undo.removeLast();
        board.restore(a, b);
      case MoveType.hint:
        break;
      case MoveType.shuffle:
        if (board.isCleared) {
          return VerificationResult.fail('move $k: shuffle on empty board');
        }
        (board.isDeadEnd ? forced : voluntary).add(k);
        if (reshuffle(board, c.seed, shuffles) == null) {
          return VerificationResult.fail('move $k: shuffle impossible');
        }
        shuffles++;
        undo.clear();
    }
  }

  // 3. Final state must match the claim.
  if (stateHash(board) != c.finalStateHash) {
    return VerificationResult.fail('final state hash mismatch');
  }
  final free = board.freeTiles();
  if (free.length != c.freeTileIdx.length ||
      !List.generate(
        free.length,
        (i) => free[i] == c.freeTileIdx[i],
      ).every((x) => x)) {
    return VerificationResult.fail('free tile set mismatch');
  }
  switch (c.kind) {
    case CertificateKind.deadEnd:
      if (board.isCleared) return VerificationResult.fail('board is cleared');
      if (board.legalPairs().isNotEmpty) {
        return VerificationResult.fail('a legal pair exists; not a dead end');
      }
    case CertificateKind.win:
      if (!board.isCleared) return VerificationResult.fail('board not cleared');
  }
  return VerificationResult._(true, null, forced, voluntary);
}
