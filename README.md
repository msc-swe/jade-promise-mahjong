# Jade Promise Mahjong: open rules engine and verifier

Jade Promise Mahjong is a mahjong solitaire game where **no ad ever interrupts a board, and the shuffle is always free**. Every deal can be solved, and whenever a game reaches a dead end (no matching pair left), the app replays the game from its seed to confirm it before offering a free shuffle. Each dead end produces a **certificate**.

This repository makes that claim auditable. It contains:

| Path | What it is |
|---|---|
| [`spec/certificate-v1.md`](spec/certificate-v1.md) | The rules, RNG, deal generator and certificate format, precisely enough to reimplement |
| [`packages/engine/`](packages/engine/) | The reference implementation in Dart, the same code the app runs |
| [`packages/engine/test/fixtures/`](packages/engine/test/fixtures/) | Language-neutral JSON test vectors: RNG outputs, deals, honest and tampered certificates |
| [`packages/verifier_cli/`](packages/verifier_cli/) | A command-line verifier for certificates exported from the app |

## Verify a certificate

```sh
dart pub get
dart run packages/verifier_cli/bin/verifier_cli.dart verify my-certificate.json
```

Or build a standalone binary: `dart compile exe packages/verifier_cli/bin/verifier_cli.dart -o verifier_cli`. See the [verifier README](packages/verifier_cli/README.md) for details.

## Run the tests

```sh
dart pub get
cd packages/engine && dart test
```

## Write your own verifier
Implement [`spec/certificate-v1.md`](spec/certificate-v1.md) in any language and make it pass every file in `packages/engine/test/fixtures/`. If the fixtures pass, your verifier agrees with the game.

## Compatibility
Deals and certificates stay reproducible: layouts never change once published, and any change to the RNG, generator or rules ships as a new `generatorVersion` / `ruleSetVersion` while old versions stay verifiable.

## License
Apache License 2.0; see [LICENSE](LICENSE) and [NOTICE](NOTICE). The game's name and its fairness badges are not covered by the license.

This repository is exported from the game's main (private) repository; issues and pull requests are welcome here.
