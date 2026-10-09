# digital_login_sdk example

```bash
flutter run --dart-define=DIGITAL_LOGIN_CLIENT_ID=<your-client-id> \
            --dart-define=DIGITAL_LOGIN_REDIRECT_URI=digitalloginsdk://callback
```

The redirect URI must be registered for your client in DigitalLogin. If you
change its scheme, update the `CallbackActivity` intent filter in
`android/app/src/main/AndroidManifest.xml` too.
