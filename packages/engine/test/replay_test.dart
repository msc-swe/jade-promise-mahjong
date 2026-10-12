import 'package:mahjong_engine/mahjong_engine.dart';
import 'package:test/test.dart';

Game deadEndGame() {
  for (var s = 0; ; s++) {
    final g = playRandomly('turtle', s);
    if (g.isDeadEnd) return g;
  }
}

Certificate roundTrip(Certificate c) => Certificate.decode(c.encode());

void main() {
  test('honest dead-end certificate verifies after JSON round trip', () {
    final g = deadEndGame();
    final r = verifyCertificate(roundTrip(g.certificate(clientBuild: 't')));
    expect(r.ok, isTrue, reason: r.error);
  });

  test('undo, hint and forced shuffle replay exactly', () {
    final g = deadEndGame();
    expect(g.undo(), isTrue);
    final pair = g.board.legalPairs().first;
    g.matchPair(pair.$1, pair.$2);
    expect(g.shuffle(), isTrue);
    g.hint();
    final c = roundTrip(g.certificate(clientBuild: 't'));
    final r = verifyCertificate(c);
    // After a shuffle the board is not a dead end, so as a dead-end claim
    // this must be rejected...
    expect(r.ok, g.isDeadEnd);
    // ...but continuing to a real dead end or win verifies, and the shuffle
    // is reported as forced.
    final rng = Pcg32(5, 5);
    while (!g.isWon && !g.isDeadEnd) {
      final ps = g.board.legalPairs();
      final (a, b) = ps[rng.nextBounded(ps.length)];
      g.matchPair(a, b);
    }
    final r2 = verifyCertificate(roundTrip(g.certificate(clientBuild: 't')));
    expect(r2.ok, isTrue, reason: r2.error);
    expect(r2.forcedShuffles, hasLength(1));
  });

  test('voluntary shuffle is reported as voluntary', () {
    final g = Game.start('turtle', 77);
    g.shuffle();
    final rng = Pcg32(1, 1);
    while (!g.isWon && !g.isDeadEnd) {
      final ps = g.board.legalPairs();
      final (a, b) = ps[rng.nextBounded(ps.length)];
      g.matchPair(a, b);
    }
    final r = verifyCertificate(g.certificate(clientBuild: 't'));
    expect(r.ok, isTrue, reason: r.error);
    expect(r.voluntaryShuffles, [0]);
    expect(r.forcedShuffles, isEmpty);
  });

  group('tampering is rejected', () {
    late Certificate honest;
    setUpAll(() => honest = deadEndGame().certificate(clientBuild: 't'));

    Map<String, Object?> json() => roundTrip(honest).toJson();

    test('claiming a dead end with moves dropped', () {
      final j = json();
      final moves = List.of(j['moves'] as List)..removeLast();
      j['moves'] = moves;
      expect(verifyCertificate(Certificate.fromJson(j)).ok, isFalse);
    });

    test('an illegal move', () {
      final j = json();
      final moves = (j['moves'] as List).cast<Map<String, Object?>>();
      moves[0] = {...moves[0], 'b': moves[0]['a']};
      expect(
        verifyCertificate(Certificate.fromJson(j)).error,
        contains('cannot match itself'),
      );
    });

    test('a different seed', () {
      final j = json()..['seed'] = '999999';
      expect(verifyCertificate(Certificate.fromJson(j)).ok, isFalse);
    });

    test('a forged final hash', () {
      final j = json()..['finalStateHash'] = '00' * 32;
      expect(
        verifyCertificate(Certificate.fromJson(j)).error,
        contains('hash'),
      );
    });

    test('a forged free-tile list', () {
      final j = json();
      j['freeTileIdx'] = [...(j['freeTileIdx'] as List), 143];
      expect(verifyCertificate(Certificate.fromJson(j)).ok, isFalse);
    });

    test('an unknown rule set', () {
      final j = json()..['ruleSetVersion'] = 2;
      expect(verifyCertificate(Certificate.fromJson(j)).ok, isFalse);
    });
  });

  test('a dead-end claim on a board with moves left is rejected', () {
    final g = Game.start('turtle', 1);
    final c = g.certificate(clientBuild: 't');
    expect(c.kind, CertificateKind.deadEnd);
    expect(verifyCertificate(c).error, contains('legal pair exists'));
  });

  test('a saved move log restores the identical game', () {
    final g = deadEndGame();
    g.undo();
    g.hint();
    g.shuffle();
    final restored = Game.restore(
      'turtle',
      g.seed,
      Certificate.decode(g.certificate(clientBuild: 't').encode()).moves,
    )!;
    expect(stateHash(restored.board), stateHash(g.board));
    expect(restored.moves.length, g.moves.length);
    expect(restored.count(MoveType.shuffle), 1);
  });

  test('a corrupt move log does not restore', () {
    expect(Game.restore('turtle', 1, [const Move(0, MoveType.undo)]), isNull);
    expect(Game.restore('nope', 1, const []), isNull);
  });
}
