import 'dart:convert';
import 'dart:io';

import 'package:mahjong_engine/mahjong_engine.dart';

const _usage =
    '''
Jade Promise Mahjong certificate verifier (rule set v$ruleSetVersion, generator v$generatorVersion)

Usage:
  verifier_cli verify <certificate.json>...   check one or more certificates
  verifier_cli deal <layoutId> <seed>         print a deal and its solution

A file may be a bare certificate or a test-vector fixture wrapping one.
Exit code 0 if every certificate verifies, 1 if any is rejected, 2 on bad input.''';

void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln(_usage);
    exit(2);
  }
  switch (args.first) {
    case 'verify' when args.length > 1:
      var allOk = true;
      for (final path in args.skip(1)) {
        allOk &= _verify(path);
      }
      exit(allOk ? 0 : 1);
    case 'deal' when args.length == 3:
      final deal = generateDeal(layoutById(args[1]), parseSeed(args[2]));
      stdout.writeln(
        const JsonEncoder.withIndent('  ').convert({
          'layoutId': args[1],
          'seed': args[2],
          'faces': [for (final f in deal.faces) Faces.debugName(f)],
          'solution': [
            for (final (a, b) in deal.solution) [a, b],
          ],
        }),
      );
    default:
      stderr.writeln(_usage);
      exit(2);
  }
}

bool _verify(String path) {
  try {
    var json =
        jsonDecode(File(path).readAsStringSync()) as Map<String, Object?>;
    if (json['type'] == 'certificate') {
      json = json['certificate'] as Map<String, Object?>;
    }
    final cert = Certificate.fromJson(json);
    final r = verifyCertificate(cert);
    final shuffles = r.ok
        ? ' (${cert.moves.length} moves; forced shuffles at ${r.forcedShuffles},'
              ' voluntary at ${r.voluntaryShuffles})'
        : '';
    stdout.writeln('$path: $r$shuffles');
    return r.ok;
  } on FormatException catch (e) {
    stdout.writeln('$path: REJECTED: ${e.message}');
    return false;
  } on FileSystemException catch (e) {
    stderr.writeln('$path: ${e.message}');
    exit(2);
  }
}
