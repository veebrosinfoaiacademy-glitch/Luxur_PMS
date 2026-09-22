import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:pms_vbis/features/telecaller/presentation/add_lead_view.dart';
import 'package:pms_vbis/features/telecaller/repositories/telecaller_lead_repository.dart';
import 'package:pms_vbis/features/telecaller/state/telecaller_view_model.dart';

/// Pure form-validation behavior — no network. addLead()'s actual server
/// interaction (attribution, duplicate rejection) is covered in
/// telecaller_view_model_test.dart and telecaller_lead_repository_test.dart.
void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  TelecallerViewModel buildViewModel() {
    return TelecallerViewModel(TelecallerLeadRepository(PocketBase('http://127.0.0.1:8090')));
  }

  testWidgets('shows a required-field error when submitting an empty name', (tester) async {
    await tester.pumpWidget(wrap(AddLeadView(viewModel: buildViewModel())));

    await tester.enterText(find.byKey(const Key('lead_phone_field')), '9876543210');
    await tester.ensureVisible(find.byKey(const Key('add_lead_submit_button')));
    await tester.tap(find.byKey(const Key('add_lead_submit_button')));
    await tester.pump();

    expect(find.text('Name is required.'), findsOneWidget);
  });

  testWidgets('shows a required-field error when submitting an empty phone', (tester) async {
    await tester.pumpWidget(wrap(AddLeadView(viewModel: buildViewModel())));

    await tester.enterText(find.byKey(const Key('lead_name_field')), 'Test Lead');
    await tester.ensureVisible(find.byKey(const Key('add_lead_submit_button')));
    await tester.tap(find.byKey(const Key('add_lead_submit_button')));
    await tester.pump();

    expect(find.text('Mobile number is required.'), findsOneWidget);
  });

  testWidgets('shows an invalid-phone error for a malformed number', (tester) async {
    await tester.pumpWidget(wrap(AddLeadView(viewModel: buildViewModel())));

    await tester.enterText(find.byKey(const Key('lead_name_field')), 'Test Lead');
    await tester.enterText(find.byKey(const Key('lead_phone_field')), '12345');
    await tester.ensureVisible(find.byKey(const Key('add_lead_submit_button')));
    await tester.tap(find.byKey(const Key('add_lead_submit_button')));
    await tester.pump();

    expect(find.text('Enter a valid 10-digit Indian mobile number.'), findsOneWidget);
  });

  testWidgets('accepts a well-formed +91 phone number without a validation error', (tester) async {
    await tester.pumpWidget(wrap(AddLeadView(viewModel: buildViewModel())));

    await tester.enterText(find.byKey(const Key('lead_name_field')), 'Test Lead');
    await tester.enterText(find.byKey(const Key('lead_phone_field')), '+91 98765 43210');
    await tester.ensureVisible(find.byKey(const Key('add_lead_submit_button')));
    await tester.tap(find.byKey(const Key('add_lead_submit_button')));
    await tester.pump();

    expect(find.text('Enter a valid 10-digit Indian mobile number.'), findsNothing);
  });
}
