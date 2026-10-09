# Security Policy

## Reporting a vulnerability

Please do **not** open a public issue for security problems. Use
[GitHub private vulnerability reporting](https://github.com/samiragaev/digital_login_sdk/security/advisories/new)
instead. You will get an answer within 72 hours.

## Design

- The login page runs in the system browser session
  (`ASWebAuthenticationSession` / Custom Tabs), never in a WebView, so the app
  cannot read the user's credentials.
- Every request carries a fresh 256-bit `state` from `Random.secure()`. The
  callback is rejected unless it echoes exactly that value.
- PKCE (S256 only) and OpenID Connect `nonce` are available.
- Callbacks must match the configured redirect URI. Repeated `code`/`state`
  parameters and oversized codes are rejected.
- The SDK never logs, stores or transmits codes or verifiers itself, and
  `DigitalLoginResult.toString()` redacts them.
- The SDK never handles the client secret. The code exchange belongs on your
  backend.
