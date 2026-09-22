import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:pms_vbis/features/telecaller/presentation/lead_list_view.dart';
import 'package:pms_vbis/features/telecaller/repositories/telecaller_lead_repository.dart';
import 'package:pms_vbis/features/telecaller/state/telecaller_view_model.dart';
import '../support/fake_auth.dart';
import '../support/pocketbase_test_helper.dart';

/// Widget-structure checks only — the actual filter predicate is verified
/// against real data shapes in lead_search_test.dart, and end-to-end
/// list-population/search is exercised by hand against the running app
/// plus telecaller_view_model_test.dart's real-network leads assertions
/// (TestWidgetsFlutterBinding fakes all HTTP inside testWidgets, so a real
/// network-backed list can't be loaded from within a widget test here).
void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('renders a search field and refresh action', (tester) async {
    final pb = PocketBase(testPocketBaseUrl);
    fakeSignIn(pb, role: 'telecaller', name: 'Test Telecaller');
    final vm = TelecallerViewModel(TelecallerLeadRepository(pb));

    await tester.pumpWidget(wrap(LeadListView(viewModel: vm)));
    await tester.pump();

    expect(find.byKey(const Key('lead_search_field')), findsOneWidget);
    expect(find.byKey(const Key('lead_list_refresh_button')), findsOneWidget);
  });

  testWidgets('shows a terminal (non-spinner) state once loading finishes, even on failure', (tester) async {
    final pb = PocketBase(testPocketBaseUrl);
    fakeSignIn(pb, role: 'telecaller', name: 'Test Telecaller');
    final vm = TelecallerViewModel(TelecallerLeadRepository(pb));

    await tester.pumpWidget(wrap(LeadListView(viewModel: vm)));
    await tester.pump(); // initial frame: loading
    await tester.pump(const Duration(seconds: 1)); // network settles (real app) or fails fast (test binding)

    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
