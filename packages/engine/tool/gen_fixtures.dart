// Regenerates the language-neutral test vectors in test/fixtures/.
// Run from packages/engine:  dart run tool/gen_fixtures.dart
// Fixtures are the contract for every engine implementation; regenerating
// them is only legitimate together with a rule/generator version bump.
import 'dart:convert';
import 'dart:io';

import 'package:mahjong_engine/mahjong_engine.dart';

const _enc = JsonEncoder.withIndent('  ');
final _created = DateTime.utc(2026, 10, 5);

void write(String name, Object json) {
  File('test/fixtures/$name.json').writeAsStringSync('${_enc.convert(json)}\n');
  stdout.writeln('wrote $name.json');
}

Map<String, Object?> certFixture(Certificate c, {String? expectError}) {
  final r = verifyCertificate(c);
  if ((expectError == null) != r.ok) {
    throw StateError('fixture expectation mismatch: $r');
  }
  return {
    'type': 'certificate',
    'certificate': c.toJson(),
    'expect': {
      'ok': r.ok,
      if (r.ok) 'forcedShuffles': r.forcedShuffles,
      if (r.ok) 'voluntaryShuffles': r.voluntaryShuffles,
      if (!r.ok) 'errorContains': expectError,
    },
  };
}

void main() {
  write('rng_pcg32', {
    'type': 'rng',
    'cases': [
      for (final (s, q) in [(42, 54), (0, 0), (-1, 1), (123456789, 2)])
        () {
          final rng = Pcg32(s, q);
          final rngB = Pcg32(s, q);
          return {
            'initState': formatSeed(s),
            'initSeq': formatSeed(q),
            'uint32': List.generate(8, (_) => rng.nextUint32()),
            'bounded': [
              for (final b in [1, 2, 3, 7, 144, 1000003])
                [b, rngB.nextBounded(b)],
            ],
          };
        }(),
    ],
  });

  write('daily_seed', {
    'type': 'daily_seed',
    'cases': [
      for (final d in ['2026-10-04', '2026-12-31', '2027-01-01'])
        {
          'date': d,
          'seed': formatSeed(dailySeed(DateTime.parse('${d}T12:00:00Z'))),
        },
    ],
  });

  final layout = layoutById('turtle');
  write('layout_turtle', {'type': 'layout', ...layout.toJson()});

  write('deals_turtle', {
    'type': 'deal',
    'layoutId': 'turtle',
    'generatorVersion': generatorVersion,
    'cases': [
      for (final s in [0, 1, 42, -1, 20261004])
        () {
          final d = generateDeal(layout, s);
          return {
            'seed': formatSeed(s),
            'faces': d.faces,
            'initialStateHash': stateHash(d.toBoard()),
            'solution': [
              for (final (a, b) in d.solution) [a, b],
            ],
          };
        }(),
    ],
  });

  // Honest dead ends from seeded random play.
  var found = 0;
  Certificate? baseDeadEnd;
  for (var s = 0; found < 3; s++) {
    final g = playRandomly('turtle', s);
    if (!g.isDeadEnd) continue;
    final c = g.certificate(clientBuild: 'fixtures', now: _created);
    baseDeadEnd ??= c;
    write('deadend_turtle_${found++}', certFixture(c));
  }

  // Undo + hint + forced shuffle, played on to the end.
  for (var s = 100; ; s++) {
    final g = playRandomly('turtle', s);
    if (!g.isDeadEnd) continue;
    g.undo();
    g.hint();
    final (a, b) = g.board.legalPairs().first;
    g.matchPair(a, b);
    if (!g.isDeadEnd || !g.shuffle()) continue;
    final rng = Pcg32(s, 3);
    while (!g.isWon && !g.isDeadEnd) {
      final ps = g.board.legalPairs();
      final (x, y) = ps[rng.nextBounded(ps.length)];
      g.matchPair(x, y);
    }
    write(
      'shuffle_turtle',
      certFixture(g.certificate(clientBuild: 'fixtures', now: _created)),
    );
    break;
  }

  // Tampered certificates.
  final base = baseDeadEnd!.toJson();
  Certificate tampered(void Function(Map<String, Object?>) f) {
    final j = jsonDecode(jsonEncode(base)) as Map<String, Object?>;
    f(j);
    return Certificate.fromJson(j);
  }

  write(
    'reject_truncated',
    certFixture(
      tampered((j) => (j['moves'] as List).removeLast()),
      expectError: 'mismatch',
    ),
  );
  write(
    'reject_self_match',
    certFixture(
      tampered((j) {
        final m = (j['moves'] as List).first as Map<String, Object?>;
        m['b'] = m['a'];
      }),
      expectError: 'cannot match itself',
    ),
  );
  write(
    'reject_forged_hash',
    certFixture(
      tampered((j) => j['finalStateHash'] = '00' * 32),
      expectError: 'hash',
    ),
  );
  write(
    'reject_not_dead_end',
    certFixture(
      Game.start(
        'turtle',
        5,
      ).certificate(clientBuild: 'fixtures', now: _created),
      expectError: 'legal pair exists',
    ),
  );
}
