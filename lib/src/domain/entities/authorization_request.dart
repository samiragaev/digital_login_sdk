import 'package:meta/meta.dart';

/// A prepared authorization request together with the secrets that must be
/// checked when the callback arrives. Internal to the SDK.
@internal
@immutable
final class AuthorizationRequest {
  /// Creates a request.
  const AuthorizationRequest({
    required this.url,
    required this.state,
    this.codeVerifier,
    this.nonce,
  });

  /// The full URL to open in the browser.
  final Uri url;

  /// The anti-CSRF value echoed back by DigitalLogin.
  final String state;

  /// The PKCE code verifier, if PKCE is enabled.
  final String? codeVerifier;

  /// The OpenID Connect nonce, if nonce is enabled.
  final String? nonce;
}
