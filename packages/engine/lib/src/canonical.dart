import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'board_state.dart';

/// Seeds are unsigned 64-bit values, serialized as decimal strings. Inside
/// Dart they are held as the same 64 bits in a signed int.
int parseSeed(String s) => BigInt.parse(s).toUnsigned(64).toSigned(64).toInt();
String formatSeed(int seed) => BigInt.from(seed).toUnsigned(64).toString();

/// SHA-256 over: utf8("MJS-STATE-1\n" + layoutId + "\n") followed by one byte
/// per slot in layout order: the face id if present, 0xFF if removed.
String stateHash(BoardState board) {
  final bytes = <int>[
    ...utf8.encode('MJS-STATE-1\n${board.layout.id}\n'),
    for (var i = 0; i < board.layout.length; i++)
      board.present[i] ? board.faces[i] : 0xFF,
  ];
  return sha256.convert(bytes).toString();
}

/// Daily seed: first 8 bytes (big-endian) of SHA-256("daily:YYYY-MM-DD"),
/// using the UTC calendar date so every player gets the same board.
int dailySeed(DateTime when) {
  final d = when.toUtc();
  final date =
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
  return _seedFrom('daily:$date');
}

/// Seed for level [k] (1-based): first 8 bytes of SHA-256("level:k").
int levelSeed(int k) => _seedFrom('level:$k');

int _seedFrom(String label) {
  final digest = sha256.convert(utf8.encode(label)).bytes;
  var v = 0;
  for (var k = 0; k < 8; k++) {
    v = (v << 8) | digest[k];
  }
  return v;
}
