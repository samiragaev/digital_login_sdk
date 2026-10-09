import 'package:meta/meta.dart';

import '../../core/secure_random.dart';
import '../../domain/entities/authorization_request.dart';
import '../../domain/entities/digital_login_config.dart';
import '../../domain/entities/digital_login_result.dart';
import '../../domain/exceptions/digital_login_exception.dart';

/// Validates the callback URL DigitalLogin redirected to and extracts the
/// authorization code from it.
@internal
final class AuthorizationResponseParser {
  /// Creates a parser.
  const AuthorizationResponseParser();

  /// Upper bound for the code length. Real codes are far shorter; anything
  /// longer is treated as a malformed or hostile callback.
  static const int maxCodeLength = 4096;

  /// Parameters that may appear at most once. A repeated value would make it
  /// ambiguous which one was checked, so the callback is rejected.
  static const Set<String> _singleValued = {
    'code',
    'state',
    'error',
    'error_description',
    'error_uri',
    'scope',
    'iss',
  };

  /// Parses [callbackUrl] for [request].
  ///
  /// Throws a [DigitalLoginException] if the callback is not a valid answer
  /// to [request].
  DigitalLoginResult parse({
    required String callbackUrl,
    required AuthorizationRequest request,
    required DigitalLoginConfig config,
  }) {
    final callback = Uri.tryParse(callbackUrl);
    if (callback == null) {
      throw const DigitalLoginInvalidCallbackException(
        'The callback URL could not be parsed.',
      );
    }
    _ensureMatchesRedirectUri(callback, config.redirectUri);

    final parameters = _collectParameters(callback);
    final state = parameters['state'];
    final error = parameters['error'];

    if (error != null) {
      // An error response carries the state when the request had one. If it
      // is present it has to match, otherwise the response is not ours.
      if (state != null && !constantTimeEquals(state, request.state)) {
        throw const DigitalLoginStateMismatchException();
      }
      final errorUri = parameters['error_uri'];
      throw DigitalLoginAuthorizationException(
        error: error,
        errorDescription: parameters['error_description'],
        errorUri: errorUri == null ? null : Uri.tryParse(errorUri),
      );
    }

    if (state == null || !constantTimeEquals(state, request.state)) {
      throw const DigitalLoginStateMismatchException();
    }

    final code = parameters['code'];
    if (code == null || code.isEmpty) {
      throw const DigitalLoginInvalidCallbackException(
        'The callback does not contain an authorization code.',
      );
    }
    if (code.length > maxCodeLength) {
      throw const DigitalLoginInvalidCallbackException(
        'The authorization code is unexpectedly long.',
      );
    }

    final scope = parameters['scope'];
    return DigitalLoginResult(
      code: code,
      redirectUri: config.redirectUriString,
      codeVerifier: request.codeVerifier,
      nonce: request.nonce,
      grantedScopes: scope?.split(' ').where((s) => s.isNotEmpty).toSet(),
    );
  }

  void _ensureMatchesRedirectUri(Uri callback, Uri redirectUri) {
    final sameScheme = callback.scheme.toLowerCase() == redirectUri.scheme;
    final sameHost =
        callback.host.toLowerCase() == redirectUri.host.toLowerCase();
    final samePort = !redirectUri.hasPort || callback.port == redirectUri.port;
    final samePath =
        _normalizePath(callback.path) == _normalizePath(redirectUri.path);
    if (!(sameScheme && sameHost && samePort && samePath)) {
      throw const DigitalLoginInvalidCallbackException(
        'The callback URL does not match the configured redirectUri.',
      );
    }
  }

  static String _normalizePath(String path) =>
      path.endsWith('/') ? path.substring(0, path.length - 1) : path;

  /// Merges query and fragment parameters. Some providers put the response
  /// in the fragment, so both are accepted, but a security relevant key may
  /// only appear once across the two.
  Map<String, String> _collectParameters(Uri callback) {
    final all = <String, List<String>>{};
    void add(Map<String, List<String>> source) {
      source.forEach((key, values) => (all[key] ??= []).addAll(values));
    }

    try {
      add(callback.queryParametersAll);
      if (callback.fragment.isNotEmpty) {
        add(Uri(query: callback.fragment).queryParametersAll);
      }
    } on FormatException {
      throw const DigitalLoginInvalidCallbackException(
        'The callback URL contains malformed parameters.',
      );
    }

    for (final key in _singleValued) {
      if ((all[key]?.length ?? 0) > 1) {
        throw DigitalLoginInvalidCallbackException(
          'The callback repeats the "$key" parameter.',
        );
      }
    }
    return {
      for (final entry in all.entries)
        if (entry.value.isNotEmpty) entry.key: entry.value.first,
    };
  }
}
