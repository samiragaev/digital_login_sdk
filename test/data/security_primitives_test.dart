import 'package:digital_login_sdk/src/core/secure_random.dart';
import 'package:digital_login_sdk/src/data/services/pkce_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PkceGenerator', () {
    test('matches the RFC 7636 appendix B test vector', () {
      expect(
        PkceGenerator.challengeFor(
            'dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk'),
        'E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM',
      );
    });

    test('verifier has a valid length and charset', () {
      final pair = PkceGenerator(SecureRandomGenerator()).generate();
      expect(pair.verifier.length, inInclusiveRange(43, 128));
      expect(pair.verifier, matches(RegExp(r'^[A-Za-z0-9\-._~]+$')));
      expect(pair.challenge, PkceGenerator.challengeFor(pair.verifier));
    });
  });

  group('SecureRandomGenerator', () {
    test('tokens are unpadded base64url with 256 bits', () {
      final token = SecureRandomGenerator().token();
      expect(token.length, 43);
      expect(token, matches(RegExp(r'^[A-Za-z0-9_-]+$')));
    });

    test('tokens do not repeat', () {
      final random = SecureRandomGenerator();
      final tokens = {for (var i = 0; i < 1000; i++) random.token()};
      expect(tokens, hasLength(1000));
    });
  });

  group('constantTimeEquals', () {
    test('compares by value', () {
      expect(constantTimeEquals('abc', 'abc'), isTrue);
      expect(constantTimeEquals('abc', 'abd'), isFalse);
      expect(constantTimeEquals('abc', 'ab'), isFalse);
      expect(constantTimeEquals('', ''), isTrue);
    });
  });
}
