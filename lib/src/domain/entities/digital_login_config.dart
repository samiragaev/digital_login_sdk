import 'package:meta/meta.dart';

import '../exceptions/digital_login_exception.dart';
import 'digital_login_environment.dart';
import 'digital_login_scope.dart';

/// Everything the SDK needs to start a DigitalLogin authorization.
///
/// The configuration is validated when it is created, so a mistake such as an
/// `http` redirect URI fails fast during development instead of at sign-in.
@immutable
final class DigitalLoginConfig {
  /// Creates and validates a configuration.
  ///
  /// Throws [DigitalLoginConfigurationException] if a value is invalid.
  DigitalLoginConfig({
    required this.clientId,
    required this.redirectUri,
    DigitalLoginEnvironment? environment,
    Set<DigitalLoginScope>? scopes,
    this.usePkce = false,
    this.useNonce = false,
    this.preferEphemeralSession = false,
    Map<String, String> additionalParameters = const {},
  }) : environment = environment ?? DigitalLoginEnvironment.production,
       scopes = Set.unmodifiable(scopes ?? DigitalLoginScope.defaults),
       additionalParameters = Map.unmodifiable(additionalParameters) {
    _validate();
  }

  /// Parameters the SDK controls. They cannot be overridden through
  /// [additionalParameters], which keeps state and PKCE handling intact.
  static const Set<String> reservedParameters = {
    'response_type',
    'client_id',
    'redirect_uri',
    'scope',
    'state',
    'nonce',
    'code_challenge',
    'code_challenge_method',
  };

  static final RegExp _schemePattern = RegExp(r'^[a-z][a-z0-9+.-]*$');
  static final RegExp _clientIdPattern = RegExp(r'^[\x21-\x7E]+$');

  /// The client identifier issued by DigitalLogin.
  final String clientId;

  /// Where DigitalLogin sends the user back, e.g. `myapp://digitallogin`.
  ///
  /// Must exactly match the redirect URI registered with DigitalLogin. Either
  /// a lowercase custom scheme or an `https` App Link / Universal Link.
  final Uri redirectUri;

  /// The DigitalLogin deployment to use. Defaults to production.
  final DigitalLoginEnvironment environment;

  /// The permissions to request. Defaults to [DigitalLoginScope.defaults].
  final Set<DigitalLoginScope> scopes;

  /// Adds a PKCE (RFC 7636, S256) challenge to the request.
  ///
  /// When enabled, [DigitalLoginResult.codeVerifier] must be forwarded to
  /// your backend and sent with the token request. Enable it only if your
  /// DigitalLogin client accepts PKCE.
  final bool usePkce;

  /// Adds an OpenID Connect `nonce` to the request.
  ///
  /// When enabled, your backend should verify that the `nonce` claim of the
  /// ID token equals [DigitalLoginResult.nonce].
  final bool useNonce;

  /// Asks the platform not to share cookies with the user's browser.
  ///
  /// On iOS this uses an ephemeral `ASWebAuthenticationSession`, so the user
  /// signs in every time and no confirmation dialog is shown.
  final bool preferEphemeralSession;

  /// Extra query parameters appended to the authorization request.
  final Map<String, String> additionalParameters;

  /// The redirect URI exactly as it is sent to DigitalLogin.
  String get redirectUriString => redirectUri.toString();

  /// Whether [redirectUri] is an `https` App Link / Universal Link.
  bool get usesHttpsRedirect => redirectUri.scheme == 'https';

  void _validate() {
    if (clientId.isEmpty || !_clientIdPattern.hasMatch(clientId)) {
      throw const DigitalLoginConfigurationException(
        'clientId must be a non-empty string without whitespace.',
      );
    }

    final scheme = redirectUri.scheme;
    if (!_schemePattern.hasMatch(scheme)) {
      throw DigitalLoginConfigurationException(
        'redirectUri must have a lowercase scheme, got "$redirectUri".',
      );
    }
    if (scheme == 'http') {
      throw const DigitalLoginConfigurationException(
        'redirectUri must not use plain http. Use a custom scheme or https.',
      );
    }
    if (scheme == 'https' && redirectUri.host.isEmpty) {
      throw DigitalLoginConfigurationException(
        'An https redirectUri needs a host, got "$redirectUri".',
      );
    }
    if (redirectUri.hasFragment) {
      throw const DigitalLoginConfigurationException(
        'redirectUri must not contain a fragment (RFC 6749, section 3.1.2).',
      );
    }

    if (scopes.isEmpty) {
      throw const DigitalLoginConfigurationException(
        'At least one scope must be requested.',
      );
    }

    final overridden = additionalParameters.keys
        .where(reservedParameters.contains)
        .toList();
    if (overridden.isNotEmpty) {
      throw DigitalLoginConfigurationException(
        'additionalParameters must not override SDK managed parameters: '
        '${overridden.join(', ')}.',
      );
    }
  }

  @override
  String toString() =>
      'DigitalLoginConfig('
      'clientId: $clientId, '
      'redirectUri: $redirectUri, '
      'environment: ${environment.name}, '
      'scopes: ${scopes.join(' ')}, '
      'usePkce: $usePkce, '
      'useNonce: $useNonce)';
}
