import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pms_vbis/core/state/app_view_model.dart';
import 'package:pms_vbis/core/state/clinic_view_model.dart';
import 'package:pms_vbis/features/dashboard/presentation/dashboard_view.dart';
import 'package:pms_vbis/features/dashboard/presentation/doctor_dashboard_view.dart';
import 'package:pms_vbis/features/sessions/models/session.dart';
import 'package:pocketbase/pocketbase.dart';
import '../support/fake_clinic_repositories.dart';

/// The dashboards are laid out for a desktop window; the test binding's
/// default surface is far smaller, so give it a realistic one instead of
/// asserting against an overflowing layout.
Future<void> _pumpDesktop(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(1600, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
  await tester.pumpAndSettle();
}

void main() {
  final pb = PocketBase('http://127.0.0.1:1');

  ClinicViewModel buildClinic({
    required FakePatientRepository patients,
    required FakeConsultationRepository consultations,
    required FakeSessionRepository sessions,
    String role = 'admin',
    String name = 'Asha',
  }) {
    return ClinicViewModel(
      pb: pb,
      role: role,
      displayName: name,
      patients: patients,
      consultations: consultations,
      sessions: sessions,
      bills: FakeBillRepository(),
    );
  }

  group('Admin dashboard — Today\'s Schedule', () {
    testWidgets('groups the day into consultation, waiting for session and completed',
        (tester) async {
      final newPatient = fakePatient(id: 'p1', name: 'Nila Raj', code: 'PT-1001');
      final seenPatient = fakePatient(id: 'p2', name: 'Vikram S', code: 'PT-1002');

      final clinic = buildClinic(
        patients: FakePatientRepository(
          registeredToday: [newPatient, seenPatient],
          total: 40,
          joined: 31,
        ),
        // Vikram has already been consulted today; Nila has not.
        consultations: FakeConsultationRepository(seenPatientIds: {'p2'}),
        sessions: FakeSessionRepository(today: [
          fakeSession(
            id: 's1',
            patientId: 'p3',
            patientName: 'Meera K',
            status: SessionStatus.arrived,
          ),
          fakeSession(
            id: 's2',
            patientId: 'p4',
            patientName: 'Rahul P',
            status: SessionStatus.completed,
          ),
        ]),
      );

      await _pumpDesktop(
        tester,
        DashboardView(viewModel: AppViewModel(), clinic: clinic),
      );

      expect(find.text("Today's Schedule"), findsOneWidget);
      // The old wording must be gone — this is Admin's operational list,
      // not the Telecaller's follow-up list.
      expect(find.text("Today's Follow Ups"), findsNothing);

      expect(find.byKey(const Key('schedule_group_consultation')), findsOneWidget);
      expect(find.byKey(const Key('schedule_group_session')), findsOneWidget);
      expect(find.byKey(const Key('schedule_group_completed')), findsOneWidget);

      expect(find.text('Nila Raj'), findsOneWidget);
      expect(find.text('Waiting for Consultation'), findsOneWidget);
      expect(find.text('Meera K'), findsOneWidget);
      expect(find.text('Waiting for Session'), findsOneWidget);

      // Vikram (consulted) and Rahul (session done) are both under
      // Completed — 2 patients there, so 4 on the day in total.
      expect(find.text('4 Patients'), findsOneWidget);
    });

    testWidgets('shows the real patient counts rather than placeholder figures',
        (tester) async {
      final clinic = buildClinic(
        patients: FakePatientRepository(total: 432, joined: 298),
        consultations: FakeConsultationRepository(),
        sessions: FakeSessionRepository(),
      );

      await _pumpDesktop(
        tester,
        DashboardView(viewModel: AppViewModel(), clinic: clinic),
      );

      expect(find.text('432'), findsOneWidget);
      expect(find.text('298'), findsOneWidget);
      expect(find.text('134'), findsOneWidget); // not joined = 432 - 298
    });

    testWidgets('Patient Arrived is offered for a scheduled session and reaches the repository',
        (tester) async {
      final sessions = FakeSessionRepository(today: [
        fakeSession(
          id: 's1',
          patientId: 'p1',
          patientName: 'Nila Raj',
          status: SessionStatus.scheduled,
        ),
      ]);
      final clinic = buildClinic(
        patients: FakePatientRepository(),
        consultations: FakeConsultationRepository(),
        sessions: sessions,
      );

      await _pumpDesktop(
        tester,
        DashboardView(viewModel: AppViewModel(), clinic: clinic),
      );

      await tester.tap(find.text('Patient Arrived'));
      await tester.pumpAndSettle();

      // The dashboard never computes the arrival time itself — it just
      // asks the server to record it.
      expect(sessions.markedArrived, ['s1']);
    });
  });

  group('Admin dashboard — missed appointments', () {
    testWidgets('lists no-shows in their own section with a Call button', (tester) async {
      final clinic = buildClinic(
        patients: FakePatientRepository(),
        consultations: FakeConsultationRepository(),
        sessions: FakeSessionRepository(noShow: [
          fakeSession(
            id: 's9',
            patientId: 'p9',
            patientName: 'Arun Das',
            patientPhone: '9876512345',
            status: SessionStatus.noShow,
            scheduledDate: DateTime.now().subtract(const Duration(days: 2)),
          ),
        ]),
      );

      await _pumpDesktop(
        tester,
        DashboardView(viewModel: AppViewModel(), clinic: clinic),
      );

      final section = find.byKey(const Key('no_show_section'));
      expect(section, findsOneWidget);
      expect(find.descendant(of: section, matching: find.text('Arun Das')), findsOneWidget);
      expect(find.descendant(of: section, matching: find.text('9876512345')), findsOneWidget);
      expect(find.descendant(of: section, matching: find.text('Call')), findsOneWidget);
    });

    testWidgets('hides the section entirely when nobody missed an appointment',
        (tester) async {
      final clinic = buildClinic(
        patients: FakePatientRepository(),
        consultations: FakeConsultationRepository(),
        sessions: FakeSessionRepository(),
      );

      await _pumpDesktop(
        tester,
        DashboardView(viewModel: AppViewModel(), clinic: clinic),
      );

      expect(find.byKey(const Key('no_show_section')), findsNothing);
    });
  });

  group('Doctor dashboard', () {
    testWidgets('shows the newest patient at the top, waiting for consultation',
        (tester) async {
      final earlier = DateTime.now().subtract(const Duration(hours: 3));
      final justNow = DateTime.now();

      final clinic = buildClinic(
        role: 'doctor',
        name: 'Dr. Anjali',
        // listRegisteredToday returns newest first, as the repository sorts
        // by -created.
        patients: FakePatientRepository(registeredToday: [
          fakePatient(id: 'p2', name: 'Just Walked In', code: 'PT-1002', created: justNow),
          fakePatient(id: 'p1', name: 'Came Earlier', code: 'PT-1001', created: earlier),
        ]),
        consultations: FakeConsultationRepository(),
        sessions: FakeSessionRepository(),
      );

      await _pumpDesktop(
        tester,
        DoctorDashboardView(viewModel: AppViewModel(), clinic: clinic),
      );

      expect(find.byKey(const Key('doctors_today_patients')), findsOneWidget);
      expect(find.text('Waiting for Consultation'), findsNWidgets(2));

      final newest = tester.getTopLeft(find.text('Just Walked In'));
      final older = tester.getTopLeft(find.text('Came Earlier'));
      expect(newest.dy, lessThan(older.dy));
    });

    testWidgets('lists today\'s sessions separately, arrived patients first', (tester) async {
      final clinic = buildClinic(
        role: 'doctor',
        name: 'Dr. Anjali',
        patients: FakePatientRepository(),
        consultations: FakeConsultationRepository(),
        sessions: FakeSessionRepository(today: [
          fakeSession(
            id: 's1',
            patientId: 'p1',
            patientName: 'Still Scheduled',
            status: SessionStatus.scheduled,
          ),
          fakeSession(
            id: 's2',
            patientId: 'p2',
            patientName: 'Already Here',
            status: SessionStatus.arrived,
          ),
        ]),
      );

      await _pumpDesktop(
        tester,
        DoctorDashboardView(viewModel: AppViewModel(), clinic: clinic),
      );

      expect(find.byKey(const Key('doctors_today_sessions')), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Already Here')).dy,
        lessThan(tester.getTopLeft(find.text('Still Scheduled')).dy),
      );
    });

    testWidgets('does not show a completed session as still waiting', (tester) async {
      final clinic = buildClinic(
        role: 'doctor',
        name: 'Dr. Anjali',
        patients: FakePatientRepository(),
        consultations: FakeConsultationRepository(),
        sessions: FakeSessionRepository(today: [
          fakeSession(
            id: 's1',
            patientId: 'p1',
            patientName: 'Finished Today',
            status: SessionStatus.completed,
          ),
        ]),
      );

      await _pumpDesktop(
        tester,
        DoctorDashboardView(viewModel: AppViewModel(), clinic: clinic),
      );

      expect(find.text('Finished Today'), findsNothing);
      expect(find.text('No treatment sessions are booked for today.'), findsOneWidget);
    });
  });
}
