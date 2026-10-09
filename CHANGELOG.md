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
