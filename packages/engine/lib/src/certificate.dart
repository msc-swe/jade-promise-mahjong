import 'dart:convert';

import 'canonical.dart';

const int certificateVersion = 1;
const int ruleSetVersion = 1;
const int maxCertificateMoves = 4096;

enum MoveType { pair, undo, hint, shuffle }

class Move {
  final int n;
  final MoveType t;
  final int? a, b;

  const Move(this.n, this.t, [this.a, this.b]);

  Map<String, Object?> toJson() => {
    'n': n,
    't': t.name,
    if (a != null) 'a': a,
    if (b != null) 'b': b,
  };

  factory Move.fromJson(Map<String, Object?> j) => Move(
    j['n'] as int,
    MoveType.values.byName(j['t'] as String),
    j['a'] as int?,
    j['b'] as int?,
  );
}

enum CertificateKind { deadEnd, win }

/// A replayable record of one game. Key order in [toJson] is the canonical
/// order of the published format.
class Certificate {
  final int version;
  final CertificateKind kind;
  final int seed;
  final String layoutId;
  final int ruleSet;
  final int generator;
  final List<Move> moves;
  final String finalStateHash;
  final List<int> freeTileIdx;
  final String clientBuild;
  final DateTime createdAt;

  Certificate({
    this.version = certificateVersion,
    required this.kind,
    required this.seed,
    required this.layoutId,
    this.ruleSet = ruleSetVersion,
    required this.generator,
    required this.moves,
    required this.finalStateHash,
    required this.freeTileIdx,
    required this.clientBuild,
    required this.createdAt,
  });

  static const _kindNames = {
    CertificateKind.deadEnd: 'dead_end',
    CertificateKind.win: 'win',
  };

  Map<String, Object?> toJson() => {
    'version': version,
    'kind': _kindNames[kind],
    'seed': formatSeed(seed),
    'layoutId': layoutId,
    'ruleSetVersion': ruleSet,
    'generatorVersion': generator,
    'moves': [for (final m in moves) m.toJson()],
    'finalStateHash': finalStateHash,
    'freeTileIdx': freeTileIdx,
    'clientBuild': clientBuild,
    'createdAt': createdAt.toUtc().toIso8601String(),
  };

  String encode() => const JsonEncoder.withIndent('  ').convert(toJson());

  /// Throws [FormatException] on malformed input.
  factory Certificate.fromJson(Map<String, Object?> j) {
    try {
      final kindName = j['kind'] as String;
      final kind = _kindNames.entries
          .firstWhere(
            (e) => e.value == kindName,
            orElse: () => throw FormatException('unknown kind $kindName'),
          )
          .key;
      final moves = (j['moves'] as List).cast<Map<String, Object?>>();
      if (moves.length > maxCertificateMoves) {
        throw FormatException('more than $maxCertificateMoves moves');
      }
      return Certificate(
        version: j['version'] as int,
        kind: kind,
        seed: parseSeed(j['seed'] as String),
        layoutId: j['layoutId'] as String,
        ruleSet: j['ruleSetVersion'] as int,
        generator: j['generatorVersion'] as int,
        moves: [for (final m in moves) Move.fromJson(m)],
        finalStateHash: j['finalStateHash'] as String,
        freeTileIdx: (j['freeTileIdx'] as List).cast<int>(),
        clientBuild: j['clientBuild'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );
    } on FormatException {
      rethrow;
    } catch (e) {
      throw FormatException('malformed certificate: $e');
    }
  }

  factory Certificate.decode(String s) =>
      Certificate.fromJson(jsonDecode(s) as Map<String, Object?>);
}
