import 'package:digital_login_sdk/digital_login_sdk.dart';
import 'package:digital_login_sdk/src/data/services/authorization_response_parser.dart';
import 'package:digital_login_sdk/src/domain/entities/authorization_request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = AuthorizationResponseParser();
  const state = 'expected-state';
  final request = AuthorizationRequest(
    url: Uri.parse('https://digital.login.gov.az/grant-permission'),
    state: state,
    codeVerifier: 'verifier',
    nonce: 'nonce',
  );
  final config = DigitalLoginConfig(
    clientId: 'client',
    redirectUri: Uri.parse('myapp://digitallogin'),
  );

  DigitalLoginResult parse(String url, {DigitalLoginConfig? override}) =>
      parser.parse(
        callbackUrl: url,
        request: request,
        config: override ?? config,
      );

  Matcher throwsType<T>() => throwsA(isA<T>());

  group('success', () {
    test('reads code from the query', () {
      final result = parse('myapp://digitallogin?code=abc&state=$state');
      expect(result.code, 'abc');
      expect(result.redirectUri, 'myapp://digitallogin');
      expect(result.codeVerifier, 'verifier');
      expect(result.nonce, 'nonce');
    });

    test('reads code from the fragment', () {
      expect(parse('myapp://digitallogin#code=abc&state=$state').code, 'abc');
    });

    test('tolerates a trailing slash and scheme/host casing', () {
      expect(parse('MyApp://DigitalLogin/?code=abc&state=$state').code, 'abc');
    });

    test('reports granted scopes', () {
      final result =
          parse('myapp://digitallogin?code=a&state=$state&scope=openid%20user');
      expect(result.grantedScopes, {'openid', 'user'});
    });

    test('works with an https redirect', () {
      final https = DigitalLoginConfig(
        clientId: 'client',
        redirectUri: Uri.parse('https://example.az/auth/cb'),
      );
      final result = parse(
        'https://example.az/auth/cb?code=abc&state=$state',
        override: https,
      );
      expect(result.code, 'abc');
    });
  });

  group('state (CSRF) protection', () {
    test('rejects a missing state', () {
      expect(
        () => parse('myapp://digitallogin?code=abc'),
        throwsType<DigitalLoginStateMismatchException>(),
      );
    });

    test('rejects a different state', () {
      expect(
        () => parse('myapp://digitallogin?code=abc&state=attacker'),
        throwsType<DigitalLoginStateMismatchException>(),
      );
    });

    test('rejects an error response with a foreign state', () {
      expect(
        () => parse('myapp://digitallogin?error=access_denied&state=x'),
        throwsType<DigitalLoginStateMismatchException>(),
      );
    });
  });

  group('OAuth errors', () {
    test('maps error parameters', () {
      expect(
        () => parse(
          'myapp://digitallogin?error=access_denied'
          '&error_description=User%20declined&state=$state',
        ),
        throwsA(
          isA<DigitalLoginAuthorizationException>()
              .having((e) => e.error, 'error', 'access_denied')
              .having((e) => e.errorDescription, 'desc', 'User declined')
              .having((e) => e.isAccessDenied, 'isAccessDenied', isTrue),
        ),
      );
    });
  });

  group('malformed or hostile callbacks', () {
    test('rejects another redirect target', () {
      for (final url in [
        'evil://digitallogin?code=a&state=$state',
        'myapp://other?code=a&state=$state',
        'myapp://digitallogin/extra?code=a&state=$state',
      ]) {
        expect(
          () => parse(url),
          throwsType<DigitalLoginInvalidCallbackException>(),
          reason: url,
        );
      }
    });

    test('rejects repeated security parameters', () {
      expect(
        () => parse('myapp://digitallogin?code=a&code=b&state=$state'),
        throwsType<DigitalLoginInvalidCallbackException>(),
      );
      expect(
        () => parse('myapp://digitallogin?code=a&state=$state#state=$state'),
        throwsType<DigitalLoginInvalidCallbackException>(),
      );
    });

    test('rejects a missing or empty code', () {
      expect(
        () => parse('myapp://digitallogin?state=$state'),
        throwsType<DigitalLoginInvalidCallbackException>(),
      );
      expect(
        () => parse('myapp://digitallogin?code=&state=$state'),
        throwsType<DigitalLoginInvalidCallbackException>(),
      );
    });

    test('rejects an oversized code', () {
      final code = 'a' * (AuthorizationResponseParser.maxCodeLength + 1);
      expect(
        () => parse('myapp://digitallogin?code=$code&state=$state'),
        throwsType<DigitalLoginInvalidCallbackException>(),
      );
    });
  });
}
