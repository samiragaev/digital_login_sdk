import 'package:meta/meta.dart';

import '../../core/secure_random.dart';
import '../../domain/entities/authorization_request.dart';
import '../../domain/entities/digital_login_config.dart';
import 'pkce_generator.dart';

/// Builds the authorization URL and the secrets bound to it.
@internal
final class AuthorizationRequestBuilder {
  /// Creates a builder.
  const AuthorizationRequestBuilder({
    required SecureRandomGenerator random,
    required PkceGenerator pkce,
  })  : _random = random,
        _pkce = pkce;

  final SecureRandomGenerator _random;
  final PkceGenerator _pkce;

  /// Creates a new request for [config]. Every call uses fresh secrets.
  AuthorizationRequest build(DigitalLoginConfig config) {
    final state = _random.token();
    final nonce = config.useNonce ? _random.token() : null;
    final pkce = config.usePkce ? _pkce.generate() : null;

    final endpoint = config.environment.authorizationEndpoint;
    final parameters = <String, String>{
      ...endpoint.queryParameters,
      ...config.additionalParameters,
      'response_type': 'code',
      'client_id': config.clientId,
      'redirect_uri': config.redirectUriString,
      'scope': config.scopes.map((scope) => scope.value).join(' '),
      'state': state,
      if (nonce != null) 'nonce': nonce,
      if (pkce != null) ...{
        'code_challenge': pkce.challenge,
        'code_challenge_method': PkceGenerator.method,
      },
    };

    return AuthorizationRequest(
      url: endpoint.replace(queryParameters: parameters),
      state: state,
      codeVerifier: pkce?.verifier,
      nonce: nonce,
    );
  }
}
