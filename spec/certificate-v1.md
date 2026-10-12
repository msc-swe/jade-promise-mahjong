# Jade Promise Mahjong: Certificate Format v1

Rule set v1 · Generator v1 · Status: published. v1 is frozen; any change ships as a new version, and v1 stays verifiable.

The reference implementation is `packages/engine`, and its test vectors live in
`packages/engine/test/fixtures/`. Every implementation must pass all fixtures.

## 1. RNG
PCG32 (XSH-RR 64/32), seeded exactly like `pcg32_srandom_r(initState, initSeq)`.
- Bounded draw `[0, n)`: threshold = (2^32 − n) mod n; draw until r ≥ threshold; return r mod n.
- Shuffle: Fisher–Yates; for i = len−1 down to 1, swap i with bounded(i+1).
- Streams: the deal uses `(seed, 0)`; the k-th shuffle (k from 0) uses `(seed, k+1)`.

## 2. Tiles and layouts
- Face ids 0–41 (dots, bamboo, characters 1–9; winds E S W N; dragons R G W; flowers 1–4; seasons 1–4).
- Match class: faces 0–33 match only themselves; any flower matches any flower; any season matches any season.
- A layout is an ordered list of 144 `(x, y, z)` slots on a half-tile grid. A tile covers x..x+1 and y..y+1 on layer z. The slot index is the tile index used in moves.
- Above/below: a slot on z±1 with |dx| < 2 and |dy| < 2. Left/right: the same z, dx = ∓2, |dy| < 2.
- **Free** = present, nothing present above, and nothing present on the left or nothing present on the right.

## 3. Deal generation (reverse play)
At each step, list every pair (a < b) of unplaced slots, scanned in index order, such that:
1. all slots beneath a and b are placed;
2. a and b are both free with only the placed slots plus a and b present;
3. no left/right chain of unplaced slots starting next to a or b reaches another placed slot.

Pick one with `bounded(count)`. If no pair qualifies, restart from empty on the same stream (at most 2000 attempts). Then shuffle the canonical list of 72 face pairs (each of faces 0–33 twice as (f,f), then (34,35), (36,37), (38,39), (40,41)) and assign pair k to placement k, first face to a and second to b. Removing pairs in reverse placement order clears the board, so every deal is solvable by construction.

## 4. Shuffle
Run the same placement over the remaining slots on stream `(seed, k+1)`. To form face pairs, group the remaining faces by match class (classes ascending), sort each group ascending, and pair consecutive faces. Then Fisher–Yates the pairs and assign them as in §3. The result is always solvable. If placement fails (for example, two tiles stacked directly on each other), the shuffle is impossible and the move is invalid. The app then offers Undo only. This can happen only in very small leftover positions.

A shuffle is legal at any time. The verifier reports a shuffle as **forced** if no legal pair existed when it was made, and **voluntary** otherwise. Undo never crosses a shuffle.

## 5. Certificate JSON
```json
{ "version": 1, "kind": "dead_end" | "win", "seed": "<u64 decimal string>",
  "layoutId": "turtle", "ruleSetVersion": 1, "generatorVersion": 1,
  "moves": [ {"n": 0, "t": "pair", "a": 12, "b": 40}, {"n": 1, "t": "undo"},
             {"n": 2, "t": "hint", "a": 3, "b": 9}, {"n": 3, "t": "shuffle"} ],
  "finalStateHash": "<sha256 hex>", "freeTileIdx": [ascending slot indices],
  "clientBuild": "...", "createdAt": "<ISO-8601 UTC>" }
```
At most 4096 moves. `n` must equal the move's position in the list.

**State hash:** SHA-256 over `utf8("MJS-STATE-1\n" + layoutId + "\n")` followed by one byte per slot: the face id if present, 0xFF if removed.

**Daily seed:** the first 8 bytes, big-endian, of SHA-256(`"daily:YYYY-MM-DD"`), using the UTC date.

## 6. Verification
1. Versions are supported and the layout is known.
2. The deal regenerated from the seed is cleared by its constructive solution.
3. Every move replays legally: pairs must be free and matching; an undo must have a pair to undo; a shuffle must be possible.
4. The final state hash and the free-tile list match.
5. `dead_end`: the board is not cleared and no legal pair exists. `win`: the board is cleared.

**Trust note (Phase 1):** the app checks itself. The deal is fixed by a public, deterministic generator, and anyone can re-run this check with `verifier_cli`. Independent server attestation arrives in Phase 2.

---
This specification is licensed under the Apache License, Version 2.0, like the reference implementation.
