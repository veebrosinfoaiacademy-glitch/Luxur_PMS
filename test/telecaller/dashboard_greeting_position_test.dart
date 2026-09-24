import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pms_vbis/features/telecaller/models/telecaller_lead.dart';
import 'package:pms_vbis/features/telecaller/presentation/telecaller_dashboard_view.dart';
import 'package:pms_vbis/features/telecaller/state/telecaller_view_model.dart';
import '../support/fake_telecaller_lead_repository.dart';

/// Regression test for: the "Good Morning/Afternoon/Evening" title drifting
/// up and down with the number of rows in the Follow-Up Required table.
/// Cause was the scroll view being wrapped in `Center`, which centres
/// vertically as well as horizontally — so a short page floated down and a
/// taller one rose. The greeting must sit at the same place regardless.
void main() {
  TelecallerLead overdueLead(int n) {
    final now = DateTime.now();
    return TelecallerLead(
      id: 'lead-$n',
      name: 'Overdue Lead $n',
      phone: '98765432${(10 + n).toString().padLeft(2, '0')}',
      address: '',
      concern: '',
      telecallerId: 'tc-1',
      converted: false,
      created: now.subtract(const Duration(days: 10)),
      // Strictly before today → shows in "Follow-Up Required".
      expectedArrivalDate: DateTime(now.year, now.month, now.day).subtract(Duration(days: n)),
    );
  }

  Future<double> greetingTop(WidgetTester tester, List<TelecallerLead> leads) async {
    final viewModel = TelecallerViewModel(FakeTelecallerLeadRepository(leads: leads));
    await viewModel.loadLeads();
    await tester.pumpWidget(
      MaterialApp(
        key: UniqueKey(),
        home: Scaffold(
          body: TelecallerDashboardView(
            viewModel: viewModel,
            onAddLead: () {},
            onImport: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    return tester.getTopLeft(find.byKey(const Key('dashboard_greeting'))).dy;
  }

  testWidgets('the greeting sits at the same spot whether there are 0, 1 or 5 follow-up rows', (tester) async {
    // Tall window so even 5 rows don't fill it — this is exactly the
    // situation where the old Center() moved the content around.
    tester.view.physicalSize = const Size(1440, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final withNoRows = await greetingTop(tester, []);
    final withOneRow = await greetingTop(tester, [overdueLead(1)]);
    final withFiveRows = await greetingTop(tester, [for (var i = 1; i <= 5; i++) overdueLead(i)]);

    expect(withOneRow, withNoRows);
    expect(withFiveRows, withNoRows);
  });

  testWidgets('the greeting is anchored to the top of the page, not vertically centred', (tester) async {
    tester.view.physicalSize = const Size(1440, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final top = await greetingTop(tester, []);

    // Just the page's own top padding away from the top edge — nowhere
    // near the middle of a 1600px-tall window.
    expect(top, lessThan(100));
  });
}
