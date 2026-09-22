import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:pms_vbis/core/auth/auth_service.dart';
import 'package:pms_vbis/features/auth/presentation/login_view.dart';

/// Pure widget/validation behavior only — no real network. Real login
/// success/failure against the actual PocketBase server is covered in
/// test/auth/auth_service_test.dart, since TestWidgetsFlutterBinding fakes
/// all HTTP responses as 400 inside testWidgets, regardless of when the
/// call happens relative to pumping.
void main() {
  Widget wrap(Widget child) => MaterialApp(home: child);

  testWidgets('shows validation errors for empty fields without calling the network', (tester) async {
    final auth = AuthService(PocketBase('http://127.0.0.1:8090'));

    await tester.pumpWidget(wrap(LoginView(authService: auth)));
    await tester.tap(find.byKey(const Key('login_submit_button')));
    await tester.pump();

    expect(find.text('Email is required.'), findsOneWidget);
    expect(find.text('Password is required.'), findsOneWidget);
    expect(auth.isAuthenticated, isFalse);
  });

  testWidgets('password visibility toggle switches the field between obscured and visible', (tester) async {
    final auth = AuthService(PocketBase('http://127.0.0.1:8090'));
    await tester.pumpWidget(wrap(LoginView(authService: auth)));

    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pump();

    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
  });

  testWidgets('quick-login buttons for all 5 dev accounts are shown (dev builds only)', (tester) async {
    final auth = AuthService(PocketBase('http://127.0.0.1:8090'));
    await tester.pumpWidget(wrap(LoginView(authService: auth)));

    for (final role in ['admin', 'doctor', 'hr', 'chairman', 'telecaller']) {
      expect(find.byKey(Key('quick_login_$role')), findsOneWidget);
    }
  });

  testWidgets('tapping the Telecaller quick-login button fills email and password', (tester) async {
    final auth = AuthService(PocketBase('http://127.0.0.1:8090'));
    await tester.pumpWidget(wrap(LoginView(authService: auth)));

    await tester.ensureVisible(find.byKey(const Key('quick_login_telecaller')));
    await tester.tap(find.byKey(const Key('quick_login_telecaller')));
    await tester.pump(); // fields fill synchronously before the (blocked-in-test) login call

    final emailField = tester.widget<TextFormField>(find.byKey(const Key('login_email_field')));
    final passwordField = tester.widget<TextFormField>(find.byKey(const Key('login_password_field')));
    expect(emailField.controller!.text, 'telecaller@luxurpms.local');
    expect(passwordField.controller!.text, 'DevPass123!');
  });

  testWidgets('each quick-login button fills its own account\'s credentials', (tester) async {
    final auth = AuthService(PocketBase('http://127.0.0.1:8090'));
    await tester.pumpWidget(wrap(LoginView(authService: auth)));

    await tester.ensureVisible(find.byKey(const Key('quick_login_chairman')));
    await tester.tap(find.byKey(const Key('quick_login_chairman')));
    await tester.pump();

    final emailField = tester.widget<TextFormField>(find.byKey(const Key('login_email_field')));
    expect(emailField.controller!.text, 'chairman@luxurpms.local');
  });
}
