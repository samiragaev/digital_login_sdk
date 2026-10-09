import 'package:flutter/services.dart';
import 'package:meta/meta.dart';

import '../../domain/exceptions/digital_login_exception.dart';
import 'web_auth_data_source.dart';

/// iOS [WebAuthDataSource] backed by the SDK's own native plugin.
///
/// Besides redirects inside `ASWebAuthenticationSession`, it also accepts the
/// redirect URI when another app (for example mygov) opens it, which
/// `ASWebAuthenticationSession` alone never sees.
@internal
final class IosWebAuthDataSource implements WebAuthDataSource {
  /// Creates the data source.
  const IosWebAuthDataSource({
    MethodChannel channel = const MethodChannel('digital_login_sdk'),
  }) : _channel = channel;

  final MethodChannel _channel;

  @override
  Future<String> authenticate({
    required Uri url,
    required Uri redirectUri,
    required bool preferEphemeral,
  }) async {
    try {
      final callback = await _channel.invokeMethod<String>('authorize', {
        'url': url.toString(),
        'redirectUri': redirectUri.toString(),
        'preferEphemeral': preferEphemeral,
      });
      if (callback == null) {
        throw const DigitalLoginPlatformException(
          code: 'EMPTY_RESULT',
          message: 'The login session finished without a callback URL.',
        );
      }
      return callback;
    } on PlatformException catch (error) {
      throw switch (error.code) {
        'CANCELED' => const DigitalLoginCancelledException(),
        'IN_PROGRESS' => const DigitalLoginInProgressException(),
        _ => DigitalLoginPlatformException(
          code: error.code,
          message: error.message,
        ),
      };
    } on MissingPluginException {
      throw const DigitalLoginPlatformException(
        code: 'UNSUPPORTED_PLATFORM',
        message: 'The digital_login_sdk iOS plugin is not registered.',
      );
    }
  }
}
