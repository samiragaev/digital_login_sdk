import 'package:digital_login_sdk/digital_login_sdk.dart';
import 'package:flutter/material.dart';

// Pass your own values, e.g.
// flutter run --dart-define=DIGITAL_LOGIN_CLIENT_ID=xxxx
const _clientId = String.fromEnvironment('DIGITAL_LOGIN_CLIENT_ID');
const _redirectUri = String.fromEnvironment(
  'DIGITAL_LOGIN_REDIRECT_URI',
  defaultValue: 'digitalloginsdk://callback',
);

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DigitalLogin SDK',
      theme: ThemeData(colorSchemeSeed: const Color(0xFF0B5CAD)),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _digitalLogin = DigitalLogin(
    DigitalLoginConfig(
      clientId: _clientId.isEmpty ? 'set-your-client-id' : _clientId,
      redirectUri: Uri.parse(_redirectUri),
      environment: DigitalLoginEnvironment.test,
    ),
  );

  bool _loading = false;
  String? _message;

  Future<void> _signIn() async {
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      final result = await _digitalLogin.authorize();
      // Send result.toJson() to your backend here. It exchanges the code for
      // tokens using the client secret, which must never ship in the app.
      _show('Authorization code received (${result.code.length} chars).');
    } on DigitalLoginCancelledException {
      _show('Sign-in cancelled.');
    } on DigitalLoginAuthorizationException catch (e) {
      _show(e.isAccessDenied ? 'Access denied.' : 'DigitalLogin: ${e.error}');
    } on DigitalLoginException catch (e) {
      _show(e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _show(String message) {
    if (mounted) setState(() => _message = message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DigitalLogin SDK')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DigitalLoginButton(onPressed: _signIn, isLoading: _loading),
              if (_message != null) ...[
                const SizedBox(height: 24),
                Text(_message!, textAlign: TextAlign.center),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
