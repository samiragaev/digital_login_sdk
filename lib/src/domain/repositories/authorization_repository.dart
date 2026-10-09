import '../entities/digital_login_config.dart';
import '../entities/digital_login_result.dart';

/// Performs a DigitalLogin authorization.
///
/// Implementations throw a `DigitalLoginException` on failure.
abstract interface class AuthorizationRepository {
  /// Runs the authorization flow described by [config].
  Future<DigitalLoginResult> authorize(DigitalLoginConfig config);
}
