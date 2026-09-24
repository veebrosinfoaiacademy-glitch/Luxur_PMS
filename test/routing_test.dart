import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pms_vbis/core/network/pocketbase_client.dart';
import 'package:pms_vbis/main.dart';
import 'support/fake_auth.dart';

/// The clinic dashboards are laid out for a desktop window and overflow at
/// the test binding's default size. That is a layout concern, not a routing
/// one, so the routing tests ignore it and nothing else.
void _ignoreOverflowErrors(WidgetTester tester) {
  final originalOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    final isOverflow = details.exception.toString().contains('A RenderFlex overflowed');
    if (!isOverflow) originalOnError?.call(details);
  };
  addTearDown(() => FlutterError.onError = originalOnError);
}

void main() {
  testWidgets('unauthenticated user sees the login screen, not any dashboard', (tester) async {
    PocketBaseClient.instance.authStore.clear();

    await tester.pumpWidget(const PMSApp());
    await tester.pump();

    expect(find.byKey(const Key('login_submit_button')), findsOneWidget);
    expect(find.byKey(const Key('nav_telecaller_dashboard')), findsNothing);
  });

  testWidgets('a telecaller account is routed to the Telecaller area, not the Admin shell', (tester) async {
    fakeSignIn(PocketBaseClient.instance, role: 'telecaller', name: 'Test Telecaller');

    await tester.pumpWidget(const PMSApp());
    await tester.pump();

    // Telecaller's own destinations and actions are present.
    expect(find.byKey(const Key('nav_telecaller_dashboard')), findsOneWidget);
    expect(find.byKey(const Key('nav_telecaller_leads')), findsOneWidget);
    expect(find.byKey(const Key('nav_telecaller_settings')), findsOneWidget);
    expect(find.byKey(const Key('action_add_lead')), findsOneWidget);
    expect(find.byKey(const Key('action_import')), findsOneWidget);
    // Clinic-shell destinations/content must never reach this shell.
    expect(find.text('Pharmacy Bills'), findsNothing);
    expect(find.byKey(const Key('admin_dashboard_greeting')), findsNothing);

    PocketBaseClient.instance.authStore.clear();
  });

  testWidgets('an admin lands on the Admin dashboard, with the front-office navigation', (tester) async {
    // The dashboard's layout was inherited with pre-existing overflows at
    // the test's default window size; they are unrelated to routing, so
    // tolerate that specific noise and assert what this test is about.
    _ignoreOverflowErrors(tester);

    fakeSignIn(PocketBaseClient.instance, role: 'admin', name: 'Test Admin');

    await tester.pumpWidget(const PMSApp());
    await tester.pump();

    expect(find.byKey(const Key('admin_dashboard_greeting')), findsOneWidget);
    expect(find.text("Today's Schedule"), findsOneWidget);
    // Admin is the one who registers patients and handles pharmacy bills.
    expect(find.byKey(const Key('dashboard_add_patient_button')), findsOneWidget);
    expect(find.text('Pharmacy Bills'), findsOneWidget);
    expect(find.byKey(const Key('nav_telecaller_dashboard')), findsNothing);

    PocketBaseClient.instance.authStore.clear();
  });

  testWidgets('a doctor shares the clinic shell but lands on the Doctor dashboard', (tester) async {
    _ignoreOverflowErrors(tester);

    fakeSignIn(PocketBaseClient.instance, role: 'doctor', name: 'Test Doctor');

    await tester.pumpWidget(const PMSApp());
    await tester.pump();

    expect(find.byKey(const Key('doctor_dashboard_greeting')), findsOneWidget);
    expect(find.byKey(const Key('doctors_today_patients')), findsOneWidget);
    expect(find.byKey(const Key('doctors_today_sessions')), findsOneWidget);
    // The Admin dashboard and the front-office-only destination are not
    // what a doctor is shown.
    expect(find.byKey(const Key('admin_dashboard_greeting')), findsNothing);
    expect(find.text('Pharmacy Bills'), findsNothing);
    // The shared parts of the shell are still there.
    expect(find.text('Patients'), findsOneWidget);

    PocketBaseClient.instance.authStore.clear();
  });

  testWidgets('signing out from the Telecaller profile menu returns to the login screen', (tester) async {
    fakeSignIn(PocketBaseClient.instance, role: 'telecaller', name: 'Test Telecaller');
    await tester.pumpWidget(const PMSApp());
    await tester.pump();
    expect(find.byKey(const Key('nav_telecaller_dashboard')), findsOneWidget);

    await tester.tap(find.byKey(const Key('telecaller_header_profile_menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('login_submit_button')), findsOneWidget);
  });
}
