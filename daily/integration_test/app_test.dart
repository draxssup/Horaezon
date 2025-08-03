import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:daily/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Login flow test', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Find email and password fields
    final phoneField = find.widgetWithText(TextField, 'Phone');
    final passwordField = find.widgetWithText(TextField, 'Password');
    final loginButton = find.widgetWithText(ElevatedButton, 'Log In');

    expect(phoneField, findsOneWidget);
    expect(passwordField, findsOneWidget);
    expect(loginButton, findsOneWidget);

    // Enter phone and password (test account)
    await tester.enterText(phoneField, '9820229757');
    await tester.enterText(passwordField, 'kkk');
    await tester.pumpAndSettle();

    // Tap Login
    await tester.tap(loginButton);
    await tester.pumpAndSettle(const Duration(seconds: 5)); 

    // Check that CalendarScreen is shown
    expect(find.textContaining('Today'), findsWidgets); 

    expect(loginButton, findsNothing);
  });
}
