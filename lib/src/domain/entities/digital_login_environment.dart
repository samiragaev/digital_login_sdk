import 'package:meta/meta.dart';

import '../exceptions/digital_login_exception.dart';

/// A DigitalLogin deployment the SDK talks to.
///
/// Use [DigitalLoginEnvironment.production] for live apps and
/// [DigitalLoginEnvironment.test] while integrating. A
/// [DigitalLoginEnvironment.custom] environment is available for staging
/// setups or endpoint changes that have not been released in the SDK yet.
@immutable
final class DigitalLoginEnvironment {
  const DigitalLoginEnvironment._({
    required this.name,
    required this.authorizationEndpoint,
    required this.tokenEndpoint,
  });

  /// Creates an environment with custom endpoints.
  ///
  /// Both endpoints must use `https`; anything else throws a
  /// [DigitalLoginConfigurationException].
  factory DigitalLoginEnvironment.custom({
    required Uri authorizationEndpoint,
    required Uri tokenEndpoint,
    String name = 'custom',
  }) {
    _requireHttps(authorizationEndpoint, 'authorizationEndpoint');
    _requireHttps(tokenEndpoint, 'tokenEndpoint');
    return DigitalLoginEnvironment._(
      name: name,
      authorizationEndpoint: authorizationEndpoint,
      tokenEndpoint: tokenEndpoint,
    );
  }

  /// Live DigitalLogin (`digital.login.gov.az`).
  static final DigitalLoginEnvironment production = DigitalLoginEnvironment._(
    name: 'production',
    authorizationEndpoint:
        Uri.parse('https://digital.login.gov.az/grant-permission'),
    tokenEndpoint:
        Uri.parse('https://apidigital.login.gov.az/ssoauth/oauth2/token'),
  );

  /// Test DigitalLogin portal (`portal.login.gov.az`).
  static final DigitalLoginEnvironment test = DigitalLoginEnvironment._(
    name: 'test',
    authorizationEndpoint:
        Uri.parse('https://portal.login.gov.az/grant-permission'),
    tokenEndpoint:
        Uri.parse('https://apiportal.login.gov.az/ssoauth/oauth2/token'),
  );

  /// Human readable name, used only for diagnostics.
  final String name;

  /// The page the user is sent to in order to grant permission.
  final Uri authorizationEndpoint;

  /// The OAuth 2.0 token endpoint.
  ///
  /// The SDK never calls it: exchanging the authorization code requires the
  /// client secret, which must stay on your backend. It is exposed so that
  /// backend configuration can be kept in one place.
  final Uri tokenEndpoint;

  static void _requireHttps(Uri uri, String field) {
    if (uri.scheme != 'https' || uri.host.isEmpty) {
      throw DigitalLoginConfigurationException(
        '$field must be an absolute https URL, got "$uri".',
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      other is DigitalLoginEnvironment &&
      other.authorizationEndpoint == authorizationEndpoint &&
      other.tokenEndpoint == tokenEndpoint;

  @override
  int get hashCode => Object.hash(authorizationEndpoint, tokenEndpoint);

  @override
  String toString() => 'DigitalLoginEnvironment($name)';
}
