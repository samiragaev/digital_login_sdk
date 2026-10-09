import 'package:digital_login_sdk/digital_login_sdk.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DigitalLoginConfig config({
    String clientId = 'client',
    String redirect = 'myapp://digitallogin',
    Set<DigitalLoginScope>? scopes,
    Map<String, String> extra = const {},
  }) =>
      DigitalLoginConfig(
        clientId: clientId,
        redirectUri: Uri.parse(redirect),
        scopes: scopes,
        additionalParameters: extra,
      );

  Matcher throwsConfig() => throwsA(isA<DigitalLoginConfigurationException>());

  group('DigitalLoginConfig', () {
    test('uses production and default scopes', () {
      final c = config();
      expect(c.environment, DigitalLoginEnvironment.production);
      expect(c.scopes, DigitalLoginScope.defaults);
      expect(c.usePkce, isFalse);
    });

    test('accepts a custom scheme and an https redirect', () {
      expect(() => config(redirect: 'my.app-1://cb'), returnsNormally);
      expect(
        () => config(redirect: 'https://example.az/auth/callback'),
        returnsNormally,
      );
    });

    test('rejects an empty or whitespace client id', () {
      expect(() => config(clientId: ''), throwsConfig());
      expect(() => config(clientId: 'a b'), throwsConfig());
    });

    test('rejects insecure or malformed redirect URIs', () {
      expect(() => config(redirect: 'http://example.az/cb'), throwsConfig());
      expect(() => config(redirect: 'https:///cb'), throwsConfig());
      expect(() => config(redirect: '/relative'), throwsConfig());
      expect(() => config(redirect: 'myapp://cb#frag'), throwsConfig());
    });

    test('rejects empty scopes', () {
      expect(() => config(scopes: {}), throwsConfig());
    });

    test('rejects overriding SDK managed parameters', () {
      for (final key in DigitalLoginConfig.reservedParameters) {
        expect(() => config(extra: {key: 'x'}), throwsConfig(), reason: key);
      }
      expect(() => config(extra: {'ui_locales': 'az'}), returnsNormally);
    });

    test('collections are immutable', () {
      final c = config();
      expect(
          () => c.scopes.add(DigitalLoginScope.openid), throwsUnsupportedError);
      expect(
        () => c.additionalParameters['a'] = 'b',
        throwsUnsupportedError,
      );
    });
  });

  group('DigitalLoginScope', () {
    test('custom scopes equal predefined ones by value', () {
      expect(DigitalLoginScope.custom('openid'), DigitalLoginScope.openid);
    });

    test('rejects invalid scope tokens', () {
      for (final value in ['', 'a b', 'a"b', r'a\b']) {
        expect(
          () => DigitalLoginScope.custom(value),
          throwsA(isA<DigitalLoginConfigurationException>()),
          reason: value,
        );
      }
    });
  });

  group('DigitalLoginEnvironment', () {
    test('custom endpoints must be https', () {
      expect(
        () => DigitalLoginEnvironment.custom(
          authorizationEndpoint: Uri.parse('http://x.az/auth'),
          tokenEndpoint: Uri.parse('https://x.az/token'),
        ),
        throwsA(isA<DigitalLoginConfigurationException>()),
      );
    });

    test('predefined endpoints are https', () {
      for (final env in [
        DigitalLoginEnvironment.production,
        DigitalLoginEnvironment.test,
      ]) {
        expect(env.authorizationEndpoint.scheme, 'https');
        expect(env.tokenEndpoint.scheme, 'https');
      }
    });
  });

  group('DigitalLoginResult', () {
    test('toString never prints secrets', () {
      const result = DigitalLoginResult(
        code: 'secret-code',
        redirectUri: 'myapp://cb',
        codeVerifier: 'secret-verifier',
        nonce: 'secret-nonce',
      );
      expect(result.toString(), isNot(contains('secret')));
    });

    test('toJson contains what the backend needs', () {
      const result = DigitalLoginResult(
        code: 'c',
        redirectUri: 'myapp://cb',
        codeVerifier: 'v',
      );
      expect(result.toJson(), {
        'authorizationCode': 'c',
        'redirectUri': 'myapp://cb',
        'codeVerifier': 'v',
      });
    });
  });
}
