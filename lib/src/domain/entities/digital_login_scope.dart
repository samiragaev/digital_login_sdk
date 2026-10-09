import 'package:meta/meta.dart';

import '../exceptions/digital_login_exception.dart';

/// A permission requested from DigitalLogin.
///
/// The predefined scopes cover what DigitalLogin currently documents. Use
/// [DigitalLoginScope.custom] for anything else.
@immutable
final class DigitalLoginScope {
  const DigitalLoginScope._(this.value);

  /// Creates a scope that is not predefined by the SDK.
  ///
  /// Scope tokens may not be empty or contain whitespace, quotes or
  /// backslashes (RFC 6749, section 3.3).
  factory DigitalLoginScope.custom(String value) {
    if (!_scopeToken.hasMatch(value)) {
      throw DigitalLoginConfigurationException(
        'Invalid scope "$value". A scope must be a non-empty token without '
        'spaces, quotes or backslashes.',
      );
    }
    return DigitalLoginScope._(value);
  }

  /// OpenID Connect authentication.
  static const DigitalLoginScope openid = DigitalLoginScope._('openid');

  /// Basic user profile data.
  static const DigitalLoginScope user = DigitalLoginScope._('user');

  /// Information about the certificate used to sign in.
  static const DigitalLoginScope certificate = DigitalLoginScope._(
    'certificate',
  );

  /// Session information.
  static const DigitalLoginScope session = DigitalLoginScope._('session');

  /// Scopes requested when none are configured.
  static final Set<DigitalLoginScope> defaults = Set.unmodifiable({
    openid,
    user,
    certificate,
    session,
  });

  // RFC 6749: scope-token = 1*( %x21 / %x23-5B / %x5D-7E )
  static final RegExp _scopeToken = RegExp(r'^[\x21\x23-\x5B\x5D-\x7E]+$');

  /// The value sent in the `scope` parameter.
  final String value;

  @override
  bool operator ==(Object other) =>
      other is DigitalLoginScope && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
