import 'package:meta/meta.dart';

import '../entities/digital_login_config.dart';
import '../entities/digital_login_result.dart';
import '../repositories/authorization_repository.dart';

/// Signs the user in with DigitalLogin and returns an authorization code.
@internal
final class AuthorizeUseCase {
  /// Creates the use case.
  const AuthorizeUseCase(this._repository);

  final AuthorizationRepository _repository;

  /// Runs the use case.
  Future<DigitalLoginResult> call(DigitalLoginConfig config) =>
      _repository.authorize(config);
}
