// See test/routing_test.dart for authenticated-state coverage (Telecaller
// vs Admin routing, sign-out). This file only checks the unauthenticated
// boot state, since main.dart now gates on a real login screen instead of
// going straight to a dashboard.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pms_vbis/main.dart';
import 'package:pms_vbis/core/network/pocketbase_client.dart';

void main() {
  testWidgets('PMSApp mounts and shows the login screen when signed out', (WidgetTester tester) async {
    PocketBaseClient.instance.authStore.clear();

    await tester.pumpWidget(const PMSApp());
    await tester.pump();

    expect(find.byKey(const Key('login_submit_button')), findsOneWidget);
  });
}
