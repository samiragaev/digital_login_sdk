import 'package:flutter/services.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:meta/meta.dart';

import '../../domain/exceptions/digital_login_exception.dart';

/// Opens the login page in a secure system browser session and waits for the
/// redirect back to the app.
@internal
abstract interface class WebAuthDataSource {
  /// Opens [url] and completes with the full callback URL.
  ///
  /// Throws [DigitalLoginCancelledException] if the user closes the page and
  /// [DigitalLoginPlatformException] for other platform failures.
  Future<String> authenticate({
    required Uri url,
    required Uri redirectUri,
    required bool preferEphemeral,
  });
}

/// [WebAuthDataSource] backed by `flutter_web_auth_2`.
///
/// It uses `ASWebAuthenticationSession` on iOS and Custom Tabs on Android.
/// Both run outside the app process, so the app can never read what the user
/// types into the DigitalLogin page, unlike an embedded WebView.
@internal
final class FlutterWebAuth2DataSource implements WebAuthDataSource {
  /// Creates the data source.
  const FlutterWebAuth2DataSource();

  @override
  Future<String> authenticate({
    required Uri url,
    required Uri redirectUri,
    required bool preferEphemeral,
  }) async {
    final isHttps = redirectUri.scheme == 'https';
    try {
      return await FlutterWebAuth2.authenticate(
        url: url.toString(),
        callbackUrlScheme: redirectUri.scheme,
        options: FlutterWebAuth2Options(
          preferEphemeral: preferEphemeral,
          httpsHost: isHttps ? redirectUri.host : null,
          httpsPath: isHttps ? redirectUri.path : null,
        ),
      );
    } on PlatformException catch (error) {
      if (error.code == 'CANCELED') {
        throw const DigitalLoginCancelledException();
      }
      throw DigitalLoginPlatformException(
        code: error.code,
        message: error.message,
      );
    } on MissingPluginException {
      throw const DigitalLoginPlatformException(
        code: 'UNSUPPORTED_PLATFORM',
        message: 'DigitalLogin is not supported on this platform.',
      );
    } on ArgumentError catch (error) {
      throw DigitalLoginConfigurationException('${error.message}');
    }
  }
}
