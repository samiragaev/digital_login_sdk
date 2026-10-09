# digital_login_sdk

[![pub package](https://img.shields.io/pub/v/digital_login_sdk.svg)](https://pub.dev/packages/digital_login_sdk)
[![CI](https://github.com/samiragaev/digital_login_sdk/actions/workflows/ci.yml/badge.svg)](https://github.com/samiragaev/digital_login_sdk/actions/workflows/ci.yml)

Sign users in with **Azerbaijan DigitalLogin** (`login.gov.az`) in one call.
Supports browser sign-in and the **mygov app**.

> Unofficial package. You need a `client_id` and a registered redirect URI
> from DigitalLogin.

## How it works

1. `authorize()` opens DigitalLogin in a secure system browser sheet.
2. The user signs in (in the browser or in the mygov app).
3. The SDK validates the response and returns an **authorization code**.
4. You send the code to **your backend**, which exchanges it for tokens.
   The client secret never ships in the app.

## Requirements

| | Minimum |
|---|---|
| Flutter | 3.38 |
| Android | API 24 |
| iOS | 13.0 |

No runtime permissions are needed on either platform.

## 1. Install

```bash
flutter pub add digital_login_sdk
```

## 2. Choose a redirect URI

Use the redirect URI registered for your client, for example:

```
myapp://digitallogin
```

- `myapp` is the **scheme**: lowercase, unique to your app.
- `digitallogin` is the **host**.

Replace both values in the snippets below with your own.

## 3. Android setup

In `android/app/src/main/AndroidManifest.xml`, add this activity inside
`<application>`:

```xml
<activity
    android:name="com.linusu.flutter_web_auth_2.CallbackActivity"
    android:exported="true"
    android:taskAffinity="">
    <intent-filter android:label="digital_login_sdk">
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="myapp" android:host="digitallogin" />
    </intent-filter>
</activity>
```

> ⚠️ Remove any other `<intent-filter>` for the same scheme, for example one
> on `MainActivity` added for `app_links` or `uni_links`. Otherwise the
> redirect will not reach the SDK.

## 4. iOS setup

In `ios/Runner/Info.plist`, add the scheme inside the top-level `<dict>`:

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

The mygov app uses this entry to return the user to your app.

## 5. Sign in

```dart
import 'package:digital_login_sdk/digital_login_sdk.dart';

final digitalLogin = DigitalLogin(
  DigitalLoginConfig(
    clientId: 'YOUR_CLIENT_ID',
    redirectUri: Uri.parse('myapp://digitallogin'),
    environment: DigitalLoginEnvironment.production, // or .test
  ),
);

Future<void> signIn() async {
  try {
    final result = await digitalLogin.authorize();

    // Send to your backend:
    // { "authorizationCode": "...", "redirectUri": "myapp://digitallogin" }
    await api.post('/auth/digital-login', body: result.toJson());
  } on DigitalLoginCancelledException {
    // The user closed the login page. Usually no message is needed.
  } on DigitalLoginException catch (e) {
    // Show an error to the user.
  }
}
```

Create `DigitalLogin` once (for example in your DI container) and reuse it.

### Optional: ready-made button

```dart
DigitalLoginButton(onPressed: signIn, isLoading: isLoading)
```

## Configuration

| Option | Default | Description |
|---|---|---|
| `clientId` | required | Client ID from DigitalLogin |
| `redirectUri` | required | Must match the registered URI exactly |
| `environment` | `production` | `production`, `test`, or `DigitalLoginEnvironment.custom(...)` |
| `scopes` | `openid user certificate session` | Requested permissions |
| `usePkce` | `false` | Adds a PKCE challenge. Send `result.codeVerifier` to your backend |
| `useNonce` | `false` | Adds an OIDC nonce. Verify `result.nonce` on your backend |
| `preferEphemeralSession` | `false` | iOS: skips the "wants to use login.gov.az" prompt, but does not reuse browser cookies |

## Errors

Every error is a `DigitalLoginException`:

| Exception | Meaning |
|---|---|
| `DigitalLoginCancelledException` | The user closed the login page |
| `DigitalLoginAuthorizationException` | DigitalLogin returned an error (`e.isAccessDenied`) |
| `DigitalLoginStateMismatchException` | The response failed the security check (`state`) |
| `DigitalLoginInvalidCallbackException` | The redirect was malformed or had no code |
| `DigitalLoginConfigurationException` | Invalid config, e.g. an `http` redirect URI |
| `DigitalLoginInProgressException` | `authorize()` is already running |
| `DigitalLoginPlatformException` | The platform could not open the login page |

## Backend: exchange the code

Your backend calls the token endpoint
(`DigitalLoginEnvironment.production.tokenEndpoint`) with the code, your
client secret, and **the same** redirect URI:

```http
POST https://apidigital.login.gov.az/ssoauth/oauth2/token
Content-Type: application/x-www-form-urlencoded

grant_type=authorization_code
&code=AUTHORIZATION_CODE
&redirect_uri=myapp://digitallogin
&client_id=YOUR_CLIENT_ID
&client_secret=YOUR_CLIENT_SECRET
```

## Troubleshooting

| Symptom | Fix |
|---|---|
| Login page opens, but nothing happens after sign-in | The scheme and host in `AndroidManifest.xml` / `Info.plist` must match `redirectUri` exactly |
| Android shows an "Open with" chooser | Another intent filter uses the same scheme. Remove it (step 3) |
| iOS: nothing happens after the mygov app returns | Add `CFBundleURLTypes` (step 4) |
| `DigitalLoginConfigurationException` | `redirectUri` must be lowercase and must not use `http` |

## Security

- Sign-in runs in the system browser, never in a WebView.
- Each request has a random 256-bit `state`. The SDK rejects responses
  without it.
- Codes are never logged. The client secret never touches the app.

See [SECURITY.md](SECURITY.md) to report a vulnerability.

## License

MIT
