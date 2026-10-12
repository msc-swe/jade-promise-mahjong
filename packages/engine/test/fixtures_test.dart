import 'dart:convert';
import 'dart:io';

import 'package:mahjong_engine/mahjong_engine.dart';
import 'package:test/test.dart';

/// Runs every language-neutral fixture. The Phase 2 C# port must pass the
/// same files.
void main() {
  final files =
      Directory('test/fixtures')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  test('fixtures exist', () => expect(files, isNotEmpty));

  for (final f in files) {
    final j = jsonDecode(f.readAsStringSync()) as Map<String, Object?>;
    test(f.uri.pathSegments.last, () {
      switch (j['type']) {
        case 'rng':
          for (final c in (j['cases'] as List).cast<Map<String, Object?>>()) {
            final s = parseSeed(c['initState'] as String);
            final q = parseSeed(c['initSeq'] as String);
            final rng = Pcg32(s, q);
            expect(List.generate(8, (_) => rng.nextUint32()), c['uint32']);
            final rngB = Pcg32(s, q);
            for (final pair in (c['bounded'] as List).cast<List>()) {
              expect(rngB.nextBounded(pair[0] as int), pair[1]);
            }
          }
        case 'daily_seed':
          for (final c in (j['cases'] as List).cast<Map<String, Object?>>()) {
            final d = DateTime.parse('${c['date']}T00:00:00Z');
            expect(formatSeed(dailySeed(d)), c['seed']);
          }
        case 'layout':
          final l = layoutById(j['id'] as String);
          expect([for (final p in l.positions) p.toJson()], j['positions']);
        case 'deal':
          final l = layoutById(j['layoutId'] as String);
          for (final c in (j['cases'] as List).cast<Map<String, Object?>>()) {
            final d = generateDeal(l, parseSeed(c['seed'] as String));
            expect(d.faces, c['faces']);
            expect(stateHash(d.toBoard()), c['initialStateHash']);
            expect([
              for (final (a, b) in d.solution) [a, b],
            ], c['solution']);
          }
        case 'certificate':
          final cert = Certificate.fromJson(
            j['certificate'] as Map<String, Object?>,
          );
          final exp = j['expect'] as Map<String, Object?>;
          final r = verifyCertificate(cert);
          expect(r.ok, exp['ok'], reason: r.error);
          if (r.ok) {
            expect(r.forcedShuffles, exp['forcedShuffles']);
            expect(r.voluntaryShuffles, exp['voluntaryShuffles']);
          } else {
            expect(r.error, contains(exp['errorContains'] as String));
          }
        default:
          fail('unknown fixture type ${j['type']}');
      }
    });
  }
}
