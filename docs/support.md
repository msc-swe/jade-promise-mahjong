---
title: Support
permalink: /support/
---

# Support

Questions, problems or ideas? Email **[support@eurobaselabs.com](mailto:support@eurobaselabs.com)**. Please include your device model and the app version (shown at the bottom of the home screen).

## Common questions

**Will an ad ever interrupt a board?**
No. While you play a board, the only ad is a small banner at the top of the screen. Full-screen ads appear only *between* boards, after you clear one (never in your first three boards, and at most one every two boards). You never need to watch an ad to finish a board, to use a hint you already have, or to get the free shuffle when you are stuck.

**What does "Replay-checked" mean?**
When you run out of moves, the app replays your whole game from its starting seed and confirms that no matching pair is left. Only then does it give you the free shuffle. Each check is saved as a certificate; you can find and share them in **Settings → Your certificates**.

**How do I verify a certificate myself?**
Install [Dart](https://dart.dev/get-dart), then in a copy of [this repository](https://github.com/msc-swe/jade-promise-mahjong) run:

```sh
dart pub get
dart run packages/verifier_cli/bin/verifier_cli.dart verify my-certificate.json
```

**Can every board really be cleared?**
Yes. Each deal is generated backwards from a complete solution, so a full clear always exists. You can still get stuck by choosing pairs in an unlucky order, and that is what the free shuffle is for.

**How do I change my ad privacy choices?**
In the app, open **Settings → Privacy and ad choices** (shown where consent applies, for example in the EEA and the UK). On iPhone, you can also change tracking permission in the system Settings app under **Privacy & Security → Tracking**.

**Will I lose my progress if I change phones?**
Progress is stored only on your device, and there is no account. Reinstalling or moving to a new phone starts fresh.

[Privacy policy](../privacy/) · [Home](../)
