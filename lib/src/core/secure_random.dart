import 'dart:convert';
import 'dart:math';

import 'package:meta/meta.dart';

/// Produces unguessable, URL safe tokens from a cryptographically secure
/// random number generator.
@internal
final class SecureRandomGenerator {
  /// Creates a generator backed by [Random.secure].
  SecureRandomGenerator() : _random = Random.secure();

  /// Creates a generator with a custom source. Tests only.
  @visibleForTesting
  SecureRandomGenerator.withRandom(this._random);

  final Random _random;

  /// Returns [byteLength] random bytes encoded as unpadded base64url.
  ///
  /// 32 bytes give 256 bits of entropy, well above the 128 bits recommended
  /// for `state` and `nonce` values.
  String token({int byteLength = 32}) {
    final bytes = List<int>.generate(byteLength, (_) => _random.nextInt(256));
    return base64UrlEncodeUnpadded(bytes);
  }
}

/// Encodes [bytes] as base64url without `=` padding (RFC 4648, section 5).
@internal
String base64UrlEncodeUnpadded(List<int> bytes) =>
    base64Url.encode(bytes).replaceAll('=', '');

/// Compares two strings in time that depends only on their length, so the
/// comparison does not leak how many leading characters matched.
@internal
bool constantTimeEquals(String a, String b) {
  final left = utf8.encode(a);
  final right = utf8.encode(b);
  if (left.length != right.length) return false;
  var diff = 0;
  for (var i = 0; i < left.length; i++) {
    diff |= left[i] ^ right[i];
  }
  return diff == 0;
}
