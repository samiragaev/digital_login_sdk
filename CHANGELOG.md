## 0.2.0

- **Fix (iOS):** signing in through the mygov app now completes. The redirect
  that mygov opens through the system is caught by the SDK's own iOS plugin
  (app delegate and `UIScene` delegate), the login sheet is closed and
  `authorize()` returns. Previously the sheet stayed open and nothing
  happened.
- The iOS implementation is now a native plugin, with CocoaPods and Swift
  Package Manager support. Android keeps using `flutter_web_auth_2`.
- **Breaking:** requires Flutter 3.38 / Dart 3.10 or newer.
- iOS apps must register the redirect URI scheme in `CFBundleURLTypes`.

## 0.1.0

Initial release.

- `DigitalLogin.authorize()` runs the OAuth 2.0 authorization code flow in
  `ASWebAuthenticationSession` (iOS) and Custom Tabs (Android).
- Production and test environments, plus custom endpoints.
- Mandatory `state` validation with constant-time comparison.
- Optional PKCE (S256) and OpenID Connect `nonce`.
- Strict callback validation: redirect URI match, duplicate parameter and
  oversized code rejection.
- Sealed `DigitalLoginException` hierarchy.
- `DigitalLoginButton` widget.
