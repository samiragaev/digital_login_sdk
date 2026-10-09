import 'package:digital_login_sdk/digital_login_sdk.dart';
import 'package:digital_login_sdk/src/data/datasources/ios_web_auth_data_source.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('digital_login_sdk');
  const dataSource = IosWebAuthDataSource();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  void respond(Object? Function(MethodCall call) handler) {
    messenger.setMockMethodCallHandler(channel, (call) async => handler(call));
  }

  Future<String> authenticate() => dataSource.authenticate(
    url: Uri.parse('https://digital.login.gov.az/grant-permission?a=b'),
    redirectUri: Uri.parse('myapp://digitallogin'),
    preferEphemeral: true,
  );

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('sends the request and returns the callback URL', () async {
    MethodCall? received;
    respond((call) {
      received = call;
      return 'myapp://digitallogin?code=c&state=s';
    });

    expect(await authenticate(), 'myapp://digitallogin?code=c&state=s');
    expect(received!.method, 'authorize');
    expect(received!.arguments, {
      'url': 'https://digital.login.gov.az/grant-permission?a=b',
      'redirectUri': 'myapp://digitallogin',
      'preferEphemeral': true,
    });
  });

  test('maps platform errors to SDK exceptions', () async {
    final cases = <String, Matcher>{
      'CANCELED': isA<DigitalLoginCancelledException>(),
      'IN_PROGRESS': isA<DigitalLoginInProgressException>(),
      'START_FAILED': isA<DigitalLoginPlatformException>().having(
        (e) => e.code,
        'code',
        'START_FAILED',
      ),
    };
    for (final entry in cases.entries) {
      respond((_) => throw PlatformException(code: entry.key));
      await expectLater(
        authenticate(),
        throwsA(entry.value),
        reason: entry.key,
      );
    }
  });

  test('reports a missing plugin as a platform error', () async {
    await expectLater(
      authenticate(),
      throwsA(isA<DigitalLoginPlatformException>()),
    );
  });
}
