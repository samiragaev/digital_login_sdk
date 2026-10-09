import 'dart:async';

import 'package:digital_login_sdk/src/data/datasources/web_auth_data_source.dart';

/// A [WebAuthDataSource] whose callback is produced by a test.
class FakeWebAuthDataSource implements WebAuthDataSource {
  FakeWebAuthDataSource(this.onAuthenticate);

  /// Receives the opened URL and returns the callback URL (or throws).
  final FutureOr<String> Function(Uri url) onAuthenticate;

  Uri? lastUrl;
  Uri? lastRedirectUri;
  bool? lastPreferEphemeral;

  @override
  Future<String> authenticate({
    required Uri url,
    required Uri redirectUri,
    required bool preferEphemeral,
  }) async {
    lastUrl = url;
    lastRedirectUri = redirectUri;
    lastPreferEphemeral = preferEphemeral;
    return onAuthenticate(url);
  }
}

/// Builds a callback that echoes the state of [url], like a real server.
String echoCallback(
  Uri url, {
  String redirect = 'myapp://digitallogin',
  String code = 'auth-code-123',
}) {
  final state = url.queryParameters['state']!;
  return '$redirect?code=$code&state=${Uri.encodeQueryComponent(state)}';
}
