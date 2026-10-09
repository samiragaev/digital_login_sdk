import 'package:digital_login_sdk/digital_login_sdk.dart';
import 'package:digital_login_sdk/src/core/secure_random.dart';
import 'package:digital_login_sdk/src/data/services/authorization_request_builder.dart';
import 'package:digital_login_sdk/src/data/services/pkce_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final random = SecureRandomGenerator();
  final builder = AuthorizationRequestBuilder(
    random: random,
    pkce: PkceGenerator(random),
  );

  DigitalLoginConfig config({bool pkce = false, bool nonce = false}) =>
      DigitalLoginConfig(
        clientId: 'client-id',
        redirectUri: Uri.parse('myapp://digitallogin'),
        environment: DigitalLoginEnvironment.test,
        scopes: {DigitalLoginScope.openid, DigitalLoginScope.user},
        usePkce: pkce,
        useNonce: nonce,
        additionalParameters: const {'ui_locales': 'az'},
      );

  test('builds a standard authorization code request', () {
    final request = builder.build(config());
    final url = request.url;

    expect(url.origin, 'https://portal.login.gov.az');
    expect(url.path, '/grant-permission');
    expect(url.queryParameters, {
      'ui_locales': 'az',
      'response_type': 'code',
      'client_id': 'client-id',
      'redirect_uri': 'myapp://digitallogin',
      'scope': 'openid user',
      'state': request.state,
    });
    expect(request.codeVerifier, isNull);
    expect(request.nonce, isNull);
  });

  test('adds an S256 challenge when PKCE is enabled', () {
    final request = builder.build(config(pkce: true));
    final params = request.url.queryParameters;

    expect(params['code_challenge_method'], 'S256');
    expect(
      params['code_challenge'],
      PkceGenerator.challengeFor(request.codeVerifier!),
    );
    expect(params.values, isNot(contains(request.codeVerifier)));
  });

  test('adds a nonce when enabled', () {
    final request = builder.build(config(nonce: true));
    expect(request.nonce, isNotNull);
    expect(request.url.queryParameters['nonce'], request.nonce);
  });

  test('uses fresh secrets for every request', () {
    final a = builder.build(config(pkce: true, nonce: true));
    final b = builder.build(config(pkce: true, nonce: true));
    expect(a.state, isNot(b.state));
    expect(a.codeVerifier, isNot(b.codeVerifier));
    expect(a.nonce, isNot(b.nonce));
  });
}
