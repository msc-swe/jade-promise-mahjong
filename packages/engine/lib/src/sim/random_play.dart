import '../game.dart';
import '../rng_pcg32.dart';

/// Plays legal pairs chosen by a seeded RNG until a win or a dead end.
/// Used for fixtures and tests; not part of the rule set.
Game playRandomly(String layoutId, int seed, {int playSeed = 7}) {
  final game = Game.start(layoutId, seed);
  final rng = Pcg32(playSeed, 99);
  while (!game.isWon && !game.isDeadEnd) {
    final pairs = game.board.legalPairs();
    final (a, b) = pairs[rng.nextBounded(pairs.length)];
    game.matchPair(a, b);
  }
  return game;
}
