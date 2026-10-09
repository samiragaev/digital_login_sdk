/// Base class of every error thrown by the SDK.
///
/// The hierarchy is sealed, so a `switch` over it is exhaustive:
///
/// ```dart
/// switch (error) {
///   case DigitalLoginCancelledException():
///   case DigitalLoginAuthorizationException():
///   case DigitalLoginStateMismatchException():
///   case DigitalLoginInvalidCallbackException():
///   case DigitalLoginConfigurationException():
///   case DigitalLoginInProgressException():
///   case DigitalLoginPlatformException():
/// }
/// ```
sealed class DigitalLoginException implements Exception {
  const DigitalLoginException(this.message);

  /// A developer facing description. Not meant to be shown to end users.
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// The user closed the login page before finishing.
final class DigitalLoginCancelledException extends DigitalLoginException {
  /// Creates the exception.
  const DigitalLoginCancelledException()
      : super('The user cancelled the DigitalLogin flow.');
}

/// DigitalLogin redirected back with an OAuth 2.0 error
/// (RFC 6749, section 4.1.2.1).
final class DigitalLoginAuthorizationException extends DigitalLoginException {
  /// Creates the exception.
  const DigitalLoginAuthorizationException({
    required this.error,
    this.errorDescription,
    this.errorUri,
  }) : super('DigitalLogin returned "$error".');

  /// The `error` code, e.g. `access_denied`.
  final String error;

  /// The optional human readable `error_description`.
  final String? errorDescription;

  /// The optional `error_uri`.
  final Uri? errorUri;

  /// Whether the user, or DigitalLogin, refused to grant access.
  bool get isAccessDenied => error == 'access_denied';
}

/// The `state` in the callback did not match the request.
///
/// This can mean a forged callback (CSRF) or a stale response from an earlier
/// attempt. The callback is discarded and no code is returned.
final class DigitalLoginStateMismatchException extends DigitalLoginException {
  /// Creates the exception.
  const DigitalLoginStateMismatchException()
      : super('The state parameter in the callback is missing or invalid.');
}

/// The callback URL could not be accepted, e.g. it points to a different
/// redirect URI, has no code, or repeats a parameter.
final class DigitalLoginInvalidCallbackException extends DigitalLoginException {
  /// Creates the exception.
  const DigitalLoginInvalidCallbackException(super.message);
}

/// The SDK was configured with invalid values.
final class DigitalLoginConfigurationException extends DigitalLoginException {
  /// Creates the exception.
  const DigitalLoginConfigurationException(super.message);
}

/// [DigitalLogin.authorize] was called while another authorization was still
/// running on the same instance.
final class DigitalLoginInProgressException extends DigitalLoginException {
  /// Creates the exception.
  const DigitalLoginInProgressException()
      : super('An authorization is already in progress.');
}

/// The platform could not open or complete the login session.
final class DigitalLoginPlatformException extends DigitalLoginException {
  /// Creates the exception.
  const DigitalLoginPlatformException({
    required this.code,
    String? message,
  }) : super(message ?? 'Platform error "$code".');

  /// The platform specific error code.
  final String code;
}
