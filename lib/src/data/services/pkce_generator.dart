import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';

import '../../core/secure_random.dart';

/// A PKCE verifier and its S256 challenge.
@internal
typedef PkcePair = ({String verifier, String challenge});

/// Generates PKCE values as described in RFC 7636.
@internal
final class PkceGenerator {
  /// Creates a generator.
  const PkceGenerator(this._random);

  final SecureRandomGenerator _random;

  /// The only challenge method the SDK sends. `plain` is deliberately not
  /// supported because it offers no protection if the request is observed.
  static const String method = 'S256';

  /// Creates a fresh verifier and its challenge.
  ///
  /// 64 random bytes encode to an 86 character verifier, inside the 43–128
  /// characters RFC 7636 allows.
  PkcePair generate() {
    final verifier = _random.token(byteLength: 64);
    return (verifier: verifier, challenge: challengeFor(verifier));
  }

  /// Computes `BASE64URL(SHA256(ASCII(verifier)))`.
  static String challengeFor(String verifier) =>
      base64UrlEncodeUnpadded(sha256.convert(ascii.encode(verifier)).bytes);
}
