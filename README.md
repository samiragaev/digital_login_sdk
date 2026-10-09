# digital_login_sdk

[![pub package](https://img.shields.io/pub/v/digital_login_sdk.svg)](https://pub.dev/packages/digital_login_sdk)
[![CI](https://github.com/samiragaev/digital_login_sdk/actions/workflows/ci.yml/badge.svg)](https://github.com/samiragaev/digital_login_sdk/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Unofficial Flutter SDK for **Azerbaijan DigitalLogin** (`login.gov.az`).
Sign users in with one call. The SDK handles the browser session, `state`
validation and PKCE.

> 🇦🇿 Azərbaycan DigitalLogin üçün Flutter SDK. Bir sətirlə istifadəçini
> DigitalLogin ilə daxil edin, `authorization code` alın və backend-inizə
> göndərin.

> **Note:** This package is not affiliated with or endorsed by the
> DigitalLogin operators. You need your own `client_id` from DigitalLogin.

## Features

- ✅ One call: `await digitalLogin.authorize()`
- 📱 Works with app-to-app sign-in through the mygov app
- 🔒 Secure by default: system browser session (no WebView), mandatory
  256-bit `state`, optional PKCE (S256) and `nonce`
- 🧱 Strict callback validation against the registered redirect URI
- 🌍 Production and test environments built in
- 🎯 Sealed, typed exceptions for exhaustive error handling
- 🎨 Optional `DigitalLoginButton` widget
- 🧪 Clean Architecture, fully unit tested

## How it works

```
App ──authorize()──► DigitalLogin page (ASWebAuthenticationSession / Custom Tabs)
                          │ user signs in
App ◄──code + state── myapp://callback
 │  SDK validates state, redirect URI, parameters
 └──code──► Your backend ──code + client_secret──► DigitalLogin token endpoint
```

The SDK deliberately stops at the authorization code. Exchanging it needs the
**client secret**, which must never ship inside a mobile app.

## Installation

```bash
flutter pub add digital_login_sdk
```

### Android

Add the callback activity to `android/app/src/main/AndroidManifest.xml`
inside `<application>`. Replace the scheme with the one from your redirect
URI:

```xml
<activity
    android:name="com.linusu.flutter_web_auth_2.CallbackActivity"
    android:exported="true"
    android:taskAffinity="">
    <intent-filter android:label="digital_login_sdk">
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="myapp" />
    </intent-filter>
</activity>
```

> If your app already handles the same scheme with another deep link package
> (`app_links`, `uni_links`, …), remove that intent filter, or use a
> dedicated scheme for DigitalLogin. Otherwise Android shows a chooser and
> the result may not reach the SDK.

### iOS

Register the redirect URI scheme in `ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLName</key>
    <string>digitallogin</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>myapp</string>
    </array>
  </dict>
</array>
```

Strictly, `ASWebAuthenticationSession` does not need this when the user
signs in inside the browser. It is required when the user signs in with the
**mygov app**: mygov sends the user back through the system. The SDK catches
that redirect in both `AppDelegate` and `UIScene` based apps, closes the
login sheet and completes `authorize()`.

`https` redirect URIs (Universal Links) require iOS 17.4+.

## Usage

```dart
import 'package:digital_login_sdk/digital_login_sdk.dart';

final digitalLogin = DigitalLogin(
  DigitalLoginConfig(
    clientId: 'your-client-id',
    redirectUri: Uri.parse('myapp://digitallogin'),
    environment: DigitalLoginEnvironment.production, // or .test
  ),
);

Future<void> signIn() async {
  try {
    final result = await digitalLogin.authorize();
    // { authorizationCode, redirectUri, [codeVerifier], [nonce] }
    await myApi.post('/auth/digital-login', body: result.toJson());
  } on DigitalLoginCancelledException {
    // The user closed the page. Usually not an error.
  } on DigitalLoginAuthorizationException catch (e) {
    // DigitalLogin returned an OAuth error, e.g. e.isAccessDenied
  } on DigitalLoginException catch (e) {
    // State mismatch, invalid callback, platform error, ...
  }
}
```

### Ready made button

```dart
DigitalLoginButton(
  onPressed: signIn,
  isLoading: isLoading,
  label: 'DigitalLogin ilə daxil ol',
)
```

### Configuration

| Option | Default | Description |
|---|---|---|
| `clientId` | required | Client ID issued by DigitalLogin |
| `redirectUri` | required | Registered redirect URI (custom scheme or `https`) |
| `environment` | `production` | `production`, `test` or `DigitalLoginEnvironment.custom(...)` |
| `scopes` | `openid user certificate session` | Requested scopes |
| `usePkce` | `false` | Adds an S256 `code_challenge`; send `codeVerifier` to your backend |
| `useNonce` | `false` | Adds an OIDC `nonce`; verify it in the ID token on your backend |
| `preferEphemeralSession` | `false` | Do not share cookies with the browser (always ask to sign in) |
| `additionalParameters` | `{}` | Extra query parameters. SDK managed keys cannot be overridden |

Invalid configuration (for example an `http` redirect URI) throws
`DigitalLoginConfigurationException` immediately.

### Errors

All errors extend the sealed `DigitalLoginException`:

| Exception | When |
|---|---|
| `DigitalLoginCancelledException` | The user closed the login page |
| `DigitalLoginAuthorizationException` | DigitalLogin returned `error=...` |
| `DigitalLoginStateMismatchException` | `state` missing or wrong (possible CSRF) |
| `DigitalLoginInvalidCallbackException` | Callback does not match the redirect URI, has no code, repeats parameters |
| `DigitalLoginConfigurationException` | Invalid configuration |
| `DigitalLoginInProgressException` | `authorize()` called while another call is running |
| `DigitalLoginPlatformException` | The platform could not open the session |

## Backend: exchanging the code

Your backend sends the code to the token endpoint
(`DigitalLoginEnvironment.production.tokenEndpoint`) together with the
client secret and **the same** `redirect_uri`:

```http
POST https://apidigital.login.gov.az/ssoauth/oauth2/token
Content-Type: application/x-www-form-urlencoded

grant_type=authorization_code&code=...&redirect_uri=myapp://digitallogin
&client_id=...&client_secret=...[&code_verifier=...]
```

Check the DigitalLogin documentation for the exact authentication method
your client uses.

## Security

See [SECURITY.md](SECURITY.md) for the threat model and how to report
vulnerabilities.

## Architecture

```
lib/
├── digital_login_sdk.dart        # public API
└── src/
    ├── core/                     # secure random, constant-time compare
    ├── domain/                   # entities, exceptions, repository contract, use case
    ├── data/                     # browser data source, request builder, callback parser
    └── presentation/             # DigitalLogin facade, DigitalLoginButton
```

## Contributing

Issues and pull requests are welcome. Run `flutter analyze` and
`flutter test` before opening a PR.

## License

MIT © Samir Aghayev
