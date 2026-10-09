import 'dart:async';

import 'package:digital_login_sdk/digital_login_sdk.dart';
import 'package:digital_login_sdk/src/core/secure_random.dart';
import 'package:digital_login_sdk/src/data/repositories/authorization_repository_impl.dart';
import 'package:digital_login_sdk/src/data/services/authorization_request_builder.dart';
import 'package:digital_login_sdk/src/data/services/authorization_response_parser.dart';
import 'package:digital_login_sdk/src/data/services/pkce_generator.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fakes.dart';

void main() {
  final config = DigitalLoginConfig(
    clientId: 'client',
    redirectUri: Uri.parse('myapp://digitallogin'),
    usePkce: true,
    preferEphemeralSession: true,
  );

  DigitalLogin client(FakeWebAuthDataSource webAuth) {
    final random = SecureRandomGenerator();
    return DigitalLogin.withRepository(
      config,
      AuthorizationRepositoryImpl(
        webAuth: webAuth,
        requestBuilder: AuthorizationRequestBuilder(
          random: random,
          pkce: PkceGenerator(random),
        ),
        responseParser: const AuthorizationResponseParser(),
      ),
    );
  }

  test('returns the code from a valid callback', () async {
    final webAuth = FakeWebAuthDataSource(echoCallback);
    final result = await client(webAuth).authorize();

    expect(result.code, 'auth-code-123');
    expect(result.codeVerifier, isNotNull);
    expect(webAuth.lastRedirectUri, config.redirectUri);
    expect(webAuth.lastPreferEphemeral, isTrue);
    expect(
      webAuth.lastUrl!.queryParameters['code_challenge'],
      PkceGenerator.challengeFor(result.codeVerifier!),
    );
  });

  test('propagates cancellation', () async {
    final webAuth = FakeWebAuthDataSource(
      (_) => throw const DigitalLoginCancelledException(),
    );
    await expectLater(
      client(webAuth).authorize(),
      throwsA(isA<DigitalLoginCancelledException>()),
    );
  });

  test('rejects a replayed callback from an earlier attempt', () async {
    late Uri firstUrl;
    var attempt = 0;
    final webAuth = FakeWebAuthDataSource((url) {
      attempt++;
      if (attempt == 1) firstUrl = url;
      return echoCallback(firstUrl);
    });
    final login = client(webAuth);

    await login.authorize();
    await expectLater(
      login.authorize(),
      throwsA(isA<DigitalLoginStateMismatchException>()),
    );
  });

  test('allows only one authorization at a time', () async {
    final pending = Completer<String>();
    final webAuth = FakeWebAuthDataSource((_) => pending.future);
    final login = client(webAuth);

    final first = login.authorize();
    expect(login.isAuthorizing, isTrue);
    await expectLater(
      login.authorize(),
      throwsA(isA<DigitalLoginInProgressException>()),
    );

    pending.complete(echoCallback(webAuth.lastUrl!));
    await first;
    expect(login.isAuthorizing, isFalse);
  });

  test('resets the in-progress flag after a failure', () async {
    final webAuth = FakeWebAuthDataSource(
      (_) => throw const DigitalLoginCancelledException(),
    );
    final login = client(webAuth);
    await expectLater(login.authorize(), throwsA(anything));
    expect(login.isAuthorizing, isFalse);
  });
}
