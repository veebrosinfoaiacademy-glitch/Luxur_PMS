import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pms_vbis/core/state/app_view_model.dart';
import 'package:pms_vbis/core/state/clinic_view_model.dart';
import 'package:pms_vbis/features/patients/presentation/patient_detail_view.dart';
import 'package:pocketbase/pocketbase.dart';
import '../support/fake_clinic_repositories.dart';

/// The profile is laid out for a desktop window; give the binding a
/// realistic surface rather than asserting against an overflowing layout.
Future<void> _pumpProfile(
  WidgetTester tester, {
  required FakePatientRepository patients,
  String role = 'admin',
}) async {
  final clinic = ClinicViewModel(
    pb: PocketBase('http://127.0.0.1:1'),
    role: role,
    displayName: 'Asha',
    patients: patients,
    consultations: FakeConsultationRepository(),
    treatments: FakeTreatmentRepository(),
    sessions: FakeSessionRepository(),
    bills: FakeBillRepository(),
  );
  await clinic.openPatient(patients.profile!.id);

  tester.view.physicalSize = const Size(1600, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: PatientDetailView(viewModel: AppViewModel(), clinic: clinic),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  final patient = fakePatient(id: 'p1', name: 'Nila Raj', code: 'PT-1001');

  testWidgets('admin gets Edit Profile and Delete Profile on the patient header',
      (tester) async {
    await _pumpProfile(tester, patients: FakePatientRepository(profile: patient));

    expect(find.byKey(const Key('edit_patient_button')), findsOneWidget);
    expect(find.byKey(const Key('delete_patient_button')), findsOneWidget);
  });

  testWidgets('a doctor gets neither', (tester) async {
    await _pumpProfile(
      tester,
      patients: FakePatientRepository(profile: patient),
      role: 'doctor',
    );

    expect(find.byKey(const Key('edit_patient_button')), findsNothing);
    expect(find.byKey(const Key('delete_patient_button')), findsNothing);
  });

  testWidgets('Edit Profile opens the form pre-filled with the patient', (tester) async {
    final patients = FakePatientRepository(profile: patient);
    await _pumpProfile(tester, patients: patients);

    await tester.tap(find.byKey(const Key('edit_patient_button')));
    await tester.pumpAndSettle();

    final name = tester.widget<TextField>(find.byKey(const Key('edit_patient_name')));
    expect(name.controller!.text, 'Nila Raj');
    // The patient code is shown but is not an editable field.
    expect(find.text('#PT-1001'), findsWidgets);

    await tester.enterText(find.byKey(const Key('edit_patient_name')), 'Nila Rajan');
    await tester.tap(find.byKey(const Key('edit_patient_save')));
    await tester.pumpAndSettle();

    expect(patients.updates.single.id, 'p1');
    expect(patients.updates.single.name, 'Nila Rajan');
  });

  testWidgets('an edit with an unusable mobile number is refused, not saved',
      (tester) async {
    final patients = FakePatientRepository(profile: patient);
    await _pumpProfile(tester, patients: patients);

    await tester.tap(find.byKey(const Key('edit_patient_button')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('edit_patient_phone')), '123');
    await tester.tap(find.byKey(const Key('edit_patient_save')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('edit_patient_error')), findsOneWidget);
    expect(patients.updates, isEmpty);
  });

  testWidgets('Delete Profile confirms first, then archives rather than destroys',
      (tester) async {
    final patients = FakePatientRepository(profile: patient);
    await _pumpProfile(tester, patients: patients);

    await tester.tap(find.byKey(const Key('delete_patient_button')));
    await tester.pumpAndSettle();

    // Nothing has happened yet, and the wording says the history is kept.
    expect(patients.archived, isEmpty);
    expect(find.textContaining('archived'), findsOneWidget);
    expect(find.textContaining('nothing is permanently deleted'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Delete Profile'));
    await tester.pumpAndSettle();

    expect(patients.archived, ['p1']);
  });

  testWidgets('cancelling the delete leaves the patient alone', (tester) async {
    final patients = FakePatientRepository(profile: patient);
    await _pumpProfile(tester, patients: patients);

    await tester.tap(find.byKey(const Key('delete_patient_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(patients.archived, isEmpty);
  });
}
