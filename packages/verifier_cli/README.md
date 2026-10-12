# Jade Promise Mahjong: certificate verifier

When a game of Jade Promise Mahjong reaches a dead end (no matching pair left), the app creates a **certificate**: the deal's seed, the board layout and every move the player made. The app replays that certificate before it offers a free shuffle. This tool lets **anyone** re-run the same check independently.

## What it checks
1. **The deal was solvable.** It regenerates the board from the seed with the published, deterministic generator, then confirms the generator's own winning sequence clears it.
2. **Every logged move was legal.** Each pair was free and matching; undos and shuffles were valid.
3. **The final position matches the certificate**: the state hash and the list of free tiles.
4. **The claim is true.** For a dead end, no matching pair is left on the board.

It also reports which shuffles were **forced** (made in a genuine dead end) and which were **voluntary**.

The exact rules, RNG, generator and file format are in [`spec/certificate-v1.md`](../../spec/certificate-v1.md). Language-neutral test vectors are in [`packages/engine/test/fixtures/`](../engine/test/fixtures/), so you can write your own verifier and compare.

## Use

With the Dart SDK, from the repository root after `dart pub get`:

```sh
dart run packages/verifier_cli/bin/verifier_cli.dart verify certificate.json [more.json ...]
dart run packages/verifier_cli/bin/verifier_cli.dart deal <layoutId> <seed>   # print a deal and its winning sequence
```

Or build a standalone binary (no Dart needed to run it):

```sh
dart compile exe packages/verifier_cli/bin/verifier_cli.dart -o verifier_cli
./verifier_cli verify certificate.json
```

Example:

```
$ verifier_cli verify my-dead-end.json
my-dead-end.json: OK (43 moves; forced shuffles at [], voluntary at [])
```

The exit code is `0` if every certificate verifies, `1` if any is rejected, and `2` on unreadable input.

## Getting a certificate
In the app, open **Fairness → Your certificates**, pick one and tap **Share**. A certificate can also be shared straight from the "No moves left" panel.

## Trust model
The app runs this same check on the phone before every free shuffle; the badge says "Replay-checked". Publishing the format and this verifier makes that claim auditable by anyone. A future server will run an independent copy of the check and sign the result ("Verified").
