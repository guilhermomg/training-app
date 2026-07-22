import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/screens/login_screen.dart';

void main() {
  testWidgets('shows the Google sign-in button and title', (tester) async {
    await tester.pumpWidget(MaterialApp(home: LoginScreen(onSignIn: () async {})));
    await tester.pump();

    expect(find.text('Training'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
  });

  testWidgets('tapping the button invokes the sign-in callback', (tester) async {
    var called = false;
    await tester.pumpWidget(
      MaterialApp(home: LoginScreen(onSignIn: () async => called = true)),
    );
    await tester.pump();

    await tester.tap(find.text('Continue with Google'));
    await tester.pump();

    expect(called, isTrue);
  });
}
