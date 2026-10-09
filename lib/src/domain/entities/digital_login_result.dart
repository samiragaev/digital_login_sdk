import 'package:meta/meta.dart';

/// The outcome of a successful DigitalLogin authorization.
///
/// Send [code] and [redirectUri] (plus [codeVerifier] and [nonce] when they
/// are set) to your backend, which exchanges them for tokens. The values are
/// single use and short lived; do not persist or log them.
@immutable
final class DigitalLoginResult {
  /// Creates a result.
  const DigitalLoginResult({
    required this.code,
    required this.redirectUri,
    this.codeVerifier,
    this.nonce,
    this.grantedScopes,
  });

  /// The authorization code returned by DigitalLogin.
  final String code;

  /// The redirect URI used for the request. The token request must send
  /// exactly the same value.
  final String redirectUri;

  /// The PKCE code verifier, set when PKCE is enabled.
  final String? codeVerifier;

  /// The OpenID Connect nonce, set when nonce is enabled.
  final String? nonce;

  /// Scopes reported back by DigitalLogin, if it returned a `scope` parameter.
  final Set<String>? grantedScopes;

  /// A JSON-ready map with the fields a backend needs for the token exchange.
  Map<String, String> toJson() => {
        'authorizationCode': code,
        'redirectUri': redirectUri,
        if (codeVerifier != null) 'codeVerifier': codeVerifier!,
        if (nonce != null) 'nonce': nonce!,
      };

  // Secrets are redacted so accidental logging does not leak them.
  @override
  String toString() => 'DigitalLoginResult('
      'code: <redacted>, '
      'redirectUri: $redirectUri, '
      'codeVerifier: ${codeVerifier == null ? 'null' : '<redacted>'}, '
      'nonce: ${nonce == null ? 'null' : '<redacted>'})';
}
