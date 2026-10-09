import 'package:meta/meta.dart';

import '../core/secure_random.dart';
import '../data/datasources/web_auth_data_source.dart';
import '../data/repositories/authorization_repository_impl.dart';
import '../data/services/authorization_request_builder.dart';
import '../data/services/authorization_response_parser.dart';
import '../data/services/pkce_generator.dart';
import '../domain/entities/digital_login_config.dart';
import '../domain/entities/digital_login_result.dart';
import '../domain/exceptions/digital_login_exception.dart';
import '../domain/repositories/authorization_repository.dart';
import '../domain/usecases/authorize_use_case.dart';

/// Entry point of the SDK.
///
/// ```dart
/// final digitalLogin = DigitalLogin(
///   DigitalLoginConfig(
///     clientId: 'your-client-id',
///     redirectUri: Uri.parse('myapp://digitallogin'),
///   ),
/// );
///
/// final result = await digitalLogin.authorize();
/// await backend.signIn(result.toJson());
/// ```
///
/// Create one instance per configuration and reuse it.
final class DigitalLogin {
  /// Creates a client for [config].
  factory DigitalLogin(DigitalLoginConfig config) {
    final random = SecureRandomGenerator();
    return DigitalLogin.withRepository(
      config,
      AuthorizationRepositoryImpl(
        webAuth: const FlutterWebAuth2DataSource(),
        requestBuilder: AuthorizationRequestBuilder(
          random: random,
          pkce: PkceGenerator(random),
        ),
        responseParser: const AuthorizationResponseParser(),
      ),
    );
  }

  /// Creates a client with a custom [repository]. Tests only.
  @visibleForTesting
  DigitalLogin.withRepository(this.config, AuthorizationRepository repository)
      : _authorize = AuthorizeUseCase(repository);

  /// The configuration this client uses.
  final DigitalLoginConfig config;

  final AuthorizeUseCase _authorize;
  bool _isAuthorizing = false;

  /// Whether [authorize] is currently running.
  bool get isAuthorizing => _isAuthorizing;

  /// Opens DigitalLogin, waits for the user and returns the authorization
  /// code.
  ///
  /// Only one authorization can run at a time per instance; a second call
  /// while one is pending throws [DigitalLoginInProgressException].
  ///
  /// Throws a [DigitalLoginException] subtype on failure. Catch
  /// [DigitalLoginCancelledException] separately if closing the page should
  /// not be shown as an error.
  Future<DigitalLoginResult> authorize() async {
    if (_isAuthorizing) throw const DigitalLoginInProgressException();
    _isAuthorizing = true;
    try {
      return await _authorize(config);
    } finally {
      _isAuthorizing = false;
    }
  }
}
