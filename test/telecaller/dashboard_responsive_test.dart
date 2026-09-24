import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pms_vbis/core/network/pocketbase_client.dart';
import 'package:pms_vbis/features/telecaller/widgets/telecaller_sidebar_nav.dart';
import 'package:pms_vbis/main.dart';
import 'package:pms_vbis/shared/widgets/clinic_logo.dart';
import '../support/fake_auth.dart';

/// Renders the full Telecaller shell (sidebar + header + dashboard) at
/// several realistic window sizes and fails on any layout exception
/// (overflow, infinite-constraint, etc.) — this is what actually caught the
/// IntrinsicHeight/infinite-height bug during the redesign, not eyeballing.
void main() {
  Future<void> renderAt(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    fakeSignIn(PocketBaseClient.instance, role: 'telecaller', name: 'Dev Telecaller');
    await tester.pumpWidget(const PMSApp());
    await tester.pump();
    await tester.pump(); // let the (network-blocked-in-test) loadLeads() error path settle

    PocketBaseClient.instance.authStore.clear();
  }

  testWidgets('Telecaller dashboard renders without overflow at desktop width (1440)', (tester) async {
    await renderAt(tester, const Size(1440, 900));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Telecaller dashboard renders without overflow at a wide monitor (1920)', (tester) async {
    await renderAt(tester, const Size(1920, 1080));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Telecaller dashboard renders without overflow at a narrow/laptop width (1024)', (tester) async {
    await renderAt(tester, const Size(1024, 768));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Telecaller dashboard renders without overflow at a small laptop width (900)', (tester) async {
    await renderAt(tester, const Size(900, 700));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Telecaller sidebar stretches top-to-bottom and logo is aligned top-left', (tester) async {
    const windowSize = Size(1280, 800);
    tester.view.physicalSize = windowSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    fakeSignIn(PocketBaseClient.instance, role: 'telecaller', name: 'Dev Telecaller');
    await tester.pumpWidget(const PMSApp());
    await tester.pump();
    await tester.pump();

    // Verify TelecallerSidebarNav fills the entire viewport height from top to bottom
    final sidebarFinder = find.byType(TelecallerSidebarNav);
    expect(sidebarFinder, findsOneWidget);
    final sidebarRect = tester.getRect(sidebarFinder);
    expect(sidebarRect.top, 0.0);
    expect(sidebarRect.bottom, 800.0);
    expect(sidebarRect.height, 800.0);
    expect(sidebarRect.left, 0.0);

    // Verify ClinicLogo is centered at the top of the sidebar
    final logoFinder = find.byType(ClinicLogo);
    expect(logoFinder, findsOneWidget);
    final logoRect = tester.getRect(logoFinder);
    expect(logoRect.top, lessThanOrEqualTo(24.0));
    final sidebarCenterX = sidebarRect.center.dx;
    expect((logoRect.center.dx - sidebarCenterX).abs(), lessThan(2.0));

    PocketBaseClient.instance.authStore.clear();
  });
}
