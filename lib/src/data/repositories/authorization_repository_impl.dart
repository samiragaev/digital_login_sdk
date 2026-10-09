import 'package:meta/meta.dart';

import '../../domain/entities/digital_login_config.dart';
import '../../domain/entities/digital_login_result.dart';
import '../../domain/repositories/authorization_repository.dart';
import '../datasources/web_auth_data_source.dart';
import '../services/authorization_request_builder.dart';
import '../services/authorization_response_parser.dart';

/// Default [AuthorizationRepository]: build request, open browser, validate
/// callback.
@internal
final class AuthorizationRepositoryImpl implements AuthorizationRepository {
  /// Creates the repository.
  const AuthorizationRepositoryImpl({
    required WebAuthDataSource webAuth,
    required AuthorizationRequestBuilder requestBuilder,
    required AuthorizationResponseParser responseParser,
  }) : _webAuth = webAuth,
       _requestBuilder = requestBuilder,
       _responseParser = responseParser;

  final WebAuthDataSource _webAuth;
  final AuthorizationRequestBuilder _requestBuilder;
  final AuthorizationResponseParser _responseParser;

  @override
  Future<DigitalLoginResult> authorize(DigitalLoginConfig config) async {
    final request = _requestBuilder.build(config);
    final callbackUrl = await _webAuth.authenticate(
      url: request.url,
      redirectUri: config.redirectUri,
      preferEphemeral: config.preferEphemeralSession,
    );
    return _responseParser.parse(
      callbackUrl: callbackUrl,
      request: request,
      config: config,
    );
  }
}
