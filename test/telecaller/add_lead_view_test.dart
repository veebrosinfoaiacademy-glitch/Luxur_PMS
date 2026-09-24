import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:pms_vbis/features/telecaller/models/telecaller_lead.dart';
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

  testWidgets('shows a required-field error when submitting without an expected arrival date', (tester) async {
    await tester.pumpWidget(wrap(AddLeadView(viewModel: buildViewModel())));

    await tester.enterText(find.byKey(const Key('lead_name_field')), 'Test Lead');
    await tester.enterText(find.byKey(const Key('lead_phone_field')), '9876543210');
    await tester.ensureVisible(find.byKey(const Key('add_lead_submit_button')));
    await tester.tap(find.byKey(const Key('add_lead_submit_button')));
    await tester.pump();

    expect(find.text('Expected clinic arrival date is required.'), findsOneWidget);
  });

  testWidgets('tapping the expected arrival field opens the date picker', (tester) async {
    await tester.pumpWidget(wrap(AddLeadView(viewModel: buildViewModel())));

    await tester.tap(find.byKey(const Key('lead_expected_arrival_field')));
    await tester.pumpAndSettle();

    // Confirms the field is wired to the standard Material date picker
    // (same showDatePicker() pattern already used elsewhere in this
    // codebase, e.g. add_pharmacy_bill_dialog.dart) rather than driving the
    // picker's own internal calendar/OK-button interaction end-to-end,
    // which is framework behavior, not this form's.
    expect(find.byType(DatePickerDialog), findsOneWidget);

    // Dismiss it so it doesn't leak into later tests in this file.
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
  });

  testWidgets('editing an existing lead pre-fills the form and shows edit-mode copy', (tester) async {
    final existing = TelecallerLead(
      id: 'lead-1',
      name: 'Priya Menon',
      phone: '9876543001',
      address: 'Kochi',
      concern: 'Laser hair reduction enquiry',
      telecallerId: 'tc-1',
      converted: false,
      created: DateTime(2026, 9, 1),
      expectedArrivalDate: DateTime(2026, 9, 28),
    );

    await tester.pumpWidget(wrap(AddLeadView(
      viewModel: buildViewModel(),
      existingLead: existing,
    )));

    expect(find.text('Edit Patient'), findsWidgets);
    expect(find.text('Save Changes'), findsOneWidget);
    final nameField = tester.widget<TextFormField>(find.byKey(const Key('lead_name_field')));
    expect(nameField.controller!.text, 'Priya Menon');
    final phoneField = tester.widget<TextFormField>(find.byKey(const Key('lead_phone_field')));
    expect(phoneField.controller!.text, '9876543001');
    expect(find.text('28 September 2026'), findsOneWidget);
  });
}
