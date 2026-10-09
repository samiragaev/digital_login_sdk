import 'package:digital_login_sdk/digital_login_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('calls onPressed when tapped', (tester) async {
    var taps = 0;
    await tester.pumpWidget(host(DigitalLoginButton(onPressed: () => taps++)));

    await tester.tap(find.byType(DigitalLoginButton));
    expect(taps, 1);
    expect(find.text('DigitalLogin ilə daxil ol'), findsOneWidget);
  });

  testWidgets('is disabled and shows progress while loading', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      host(DigitalLoginButton(onPressed: () => taps++, isLoading: true)),
    );

    await tester.tap(find.byType(DigitalLoginButton));
    expect(taps, 0);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
