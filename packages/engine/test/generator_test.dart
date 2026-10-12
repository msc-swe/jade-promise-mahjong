import 'dart:io';

import 'package:mahjong_engine/mahjong_engine.dart';
import 'package:test/test.dart';

// Default 30 seeds per layout; run the full property with MJ_SEEDS=10000.
final int seeds = int.parse(Platform.environment['MJ_SEEDS'] ?? '30');

void main() {
  test('deals are deterministic', () {
    final l = layoutById('turtle');
    expect(generateDeal(l, 12345).faces, generateDeal(l, 12345).faces);
    expect(generateDeal(l, 12345).faces, isNot(generateDeal(l, 12346).faces));
  });

  test('deal uses exactly the full tile set', () {
    final faces = generateDeal(layoutById('turtle'), 1).faces;
    final counts = List.filled(Faces.count, 0);
    for (final f in faces) {
      counts[f]++;
    }
    for (var f = 0; f < Faces.count; f++) {
      expect(counts[f], f < Faces.flowerStart ? 4 : 1, reason: 'face $f');
    }
  });

  for (final id in layoutIds) {
    test('every $id deal is cleared by its constructive solution '
        '($seeds seeds)', () {
      final l = layoutById(id);
      for (var s = 0; s < seeds; s++) {
        final deal = generateDeal(l, s * 7919);
        final board = deal.toBoard();
        for (final (a, b) in deal.solution) {
          expect(board.whyIllegal(a, b), isNull, reason: 'seed $s');
          board.remove(a, b);
        }
        expect(board.isCleared, isTrue);
      }
    }, timeout: Timeout.none);
  }

  test('reshuffle keeps the face multiset and leaves the board solvable', () {
    for (var s = 0; s < 20; s++) {
      final game = playRandomly('turtle', s);
      if (game.isWon) continue;
      final before = [
        for (var i = 0; i < 144; i++)
          if (game.board.present[i]) game.board.faces[i],
      ]..sort();
      final snapshot = BoardState.copy(game.board);
      final solution = reshuffle(game.board, game.seed, 0);
      if (solution == null) continue; // unshufflable geometry
      final after = [
        for (var i = 0; i < 144; i++)
          if (game.board.present[i]) game.board.faces[i],
      ]..sort();
      expect(after, before);
      expect(game.board.present, snapshot.present);
      final check = BoardState.copy(game.board);
      for (final (a, b) in solution) {
        expect(check.whyIllegal(a, b), isNull, reason: 'seed $s');
        check.remove(a, b);
      }
      expect(check.isCleared, isTrue);
    }
  });

  test('two stacked tiles cannot be reshuffled', () {
    final l = layoutById('turtle');
    final board = generateDeal(l, 3).toBoard();
    final top = l.positions.indexWhere((p) => p.z == 4);
    final under = l.below[top].first;
    for (var i = 0; i < l.length; i++) {
      board.present[i] = i == top || i == under;
    }
    expect(reshuffle(board, 3, 0), isNull);
  });
}
