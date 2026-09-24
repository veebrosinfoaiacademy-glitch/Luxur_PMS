import 'package:flutter_test/flutter_test.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:pms_vbis/features/billing/models/bill.dart';
import 'package:pms_vbis/features/billing/repositories/bill_repository.dart';
import 'package:pms_vbis/features/consultations/models/consultation.dart';
import 'package:pms_vbis/features/consultations/repositories/consultation_repository.dart';
import 'package:pms_vbis/features/patients/repositories/patient_repository.dart';
import 'package:pms_vbis/features/sessions/models/session.dart';
import 'package:pms_vbis/features/sessions/repositories/session_repository.dart';
import 'package:pms_vbis/features/telecaller/repositories/telecaller_lead_repository.dart';
import 'package:pms_vbis/features/treatments/models/treatment_plan.dart';
import 'package:pms_vbis/features/treatments/repositories/treatment_plan_repository.dart';
import 'package:pms_vbis/features/treatments/repositories/treatment_repository.dart';
import 'package:pms_vbis/features/treatments/utils/treatment_progress.dart';
import '../support/pocketbase_test_helper.dart';

/// End-to-end workflow rules against the real local PocketBase — the parts
/// of the Admin/Doctor specification that must hold server-side no matter
/// what the Flutter UI does.
void main() {
  late final PocketBase adminPb;
  late final PocketBase doctorAPb;
  late final PocketBase doctorBPb;
  late final String doctorAId;
  late final String doctorBId;

  setUpAll(() async {
    final superuserPb = await authenticatedSuperuserClient();
    await ensureTestUser(superuserPb, testAdminEmail, role: 'admin');
    await ensureTestUser(superuserPb, testDoctorAEmail, role: 'doctor');
    await ensureTestUser(superuserPb, testDoctorBEmail, role: 'doctor');
    await ensureTestTelecaller(superuserPb, testTelecallerAEmail);
    adminPb = await authenticatedClientAs(testAdminEmail);
    doctorAPb = await authenticatedClientAs(testDoctorAEmail);
    doctorBPb = await authenticatedClientAs(testDoctorBEmail);
    doctorAId = doctorAPb.authStore.record!.id;
    doctorBId = doctorBPb.authStore.record!.id;
  });

  PatientRepository patients(PocketBase pb) =>
      PatientRepository(pb, TelecallerLeadRepository(pb));

  Future<String> newPatient({String name = 'Workflow Patient'}) async {
    final patient = await patients(adminPb).create(
      name: name,
      normalizedPhone: uniqueTestPhone(),
      source: 'Direct Walk-in',
    );
    return patient.id;
  }

  /// A completed consultation that recommends a treatment, plus that
  /// treatment — the normal precondition for session work.
  Future<(String consultationId, String treatmentId)> consultAndRecommend(
    String patientId, {
    double packageCost = 50000,
    double? consultationFee,
  }) async {
    final consultations = ConsultationRepository(doctorAPb);
    final draft = await consultations.saveDraft(patientId: patientId, reasonForVisit: 'Hair loss');
    final treatment = await TreatmentRepository(doctorAPb).create(
      patientId: patientId,
      category: TreatmentCategory.hair,
      packageName: 'Hair PRP',
      packageCost: packageCost,
      consultationId: draft.id,
    );
    await consultations.complete(
      draft.id,
      recommendation: ConsultationRecommendation.recommendTreatment,
      notes: 'Recommend PRP course.',
      consultationFee: consultationFee,
      suggestedProduct: 'Serum A',
      treatmentId: treatment.id,
    );
    return (draft.id, treatment.id);
  }

  group('Patient registration', () {
    test('registers a patient with no doctor attached to them', () async {
      final patient = await patients(adminPb).create(
        name: 'Direct Walk-in Patient',
        normalizedPhone: uniqueTestPhone(),
        source: 'Direct Walk-in',
        age: 31,
        gender: 'Female',
        concern: 'Acne',
      );

      expect(patient.patientCode, startsWith('PT-'));
      // The record carries no doctor — attribution lives on clinical records.
      final raw = await adminPb.collection('patients').getOne(patient.id);
      expect(raw.getStringValue('assigned_doctor'), isEmpty);
    });

    test('blocks a duplicate phone number and surfaces the existing patient', () async {
      final phone = uniqueTestPhone();
      final first = await patients(adminPb).create(
        name: 'First Registration',
        normalizedPhone: phone,
        source: 'Direct Walk-in',
      );

      try {
        await patients(adminPb).create(
          name: 'Second Registration',
          normalizedPhone: phone,
          source: 'Direct Walk-in',
        );
        fail('expected a DuplicatePatientException');
      } on DuplicatePatientException catch (e) {
        expect(e.existing.id, first.id);
      }
    });

    test('converting a Telecaller lead preserves its attribution on the patient', () async {
      final telecallerPb = await authenticatedTelecallerClient(testTelecallerAEmail);
      final leadRepo = TelecallerLeadRepository(telecallerPb);
      final phone = uniqueTestPhone();
      final lead = await leadRepo.create(
        name: 'Lead To Convert',
        normalizedPhone: phone,
        expectedArrivalDate: DateTime(2030, 9, 25),
      );

      // Admin finds the lead by phone and sees who added it.
      final match = await patients(adminPb).findMatchingTelecallerLead(phone);
      expect(match, isNotNull);
      expect(match!.telecallerName, isNotNull);
      expect(match.expectedArrivalDate, isNotNull);

      final patient = await patients(adminPb).create(
        name: match.name,
        normalizedPhone: phone,
        source: 'Telecalling',
        telecallerLeadId: match.id,
        telecallerId: match.telecallerId,
      );

      expect(patient.isFromTelecallerLead, isTrue);
      expect(patient.telecallerId, match.telecallerId);

      // And the lead is now marked converted, not deleted.
      final convertedLead = (await leadRepo.listMine()).firstWhere((l) => l.id == lead.id);
      expect(convertedLead.converted, isTrue);
    });
  });

  group('Editing and deleting a patient', () {
    test('admin corrects a patient\'s details without touching code or attribution',
        () async {
      final telecallerPb = await authenticatedTelecallerClient(testTelecallerAEmail);
      final phone = uniqueTestPhone();
      final lead = await TelecallerLeadRepository(telecallerPb).create(
        name: 'Mistyped Name',
        normalizedPhone: phone,
      );
      final created = await patients(adminPb).create(
        name: 'Mistyped Name',
        normalizedPhone: phone,
        source: 'Telecalling',
        age: 29,
        gender: 'Female',
        telecallerLeadId: lead.id,
        telecallerId: lead.telecallerId,
      );

      final newPhone = uniqueTestPhone();
      final updated = await patients(adminPb).update(
        created.id,
        name: 'Corrected Name',
        normalizedPhone: newPhone,
        source: 'Telecalling',
        age: 30,
        gender: 'Female',
        address: '12 Marine Drive',
        concern: 'Pigmentation',
      );

      expect(updated.name, 'Corrected Name');
      expect(updated.phone, newPhone);
      expect(updated.age, 30);
      expect(updated.address, '12 Marine Drive');
      // The identity and the Telecaller's credit both survive the edit.
      expect(updated.patientCode, created.patientCode);
      expect(updated.telecallerId, created.telecallerId);
      expect(updated.telecallerLeadId, created.telecallerLeadId);
    });

    test('clearing the age leaves it empty rather than reading as zero', () async {
      final created = await patients(adminPb).create(
        name: 'Age To Clear',
        normalizedPhone: uniqueTestPhone(),
        source: 'Direct Walk-in',
        age: 44,
      );

      final updated = await patients(adminPb).update(
        created.id,
        name: created.name,
        normalizedPhone: created.phone,
        source: created.source,
        age: null,
      );

      expect(updated.age, isNull);
    });

    test('an edit cannot move a number onto a patient that already owns it', () async {
      final takenPhone = uniqueTestPhone();
      final owner = await patients(adminPb).create(
        name: 'Number Owner',
        normalizedPhone: takenPhone,
        source: 'Direct Walk-in',
      );
      final other = await patients(adminPb).create(
        name: 'Other Patient',
        normalizedPhone: uniqueTestPhone(),
        source: 'Direct Walk-in',
      );

      try {
        await patients(adminPb).update(
          other.id,
          name: other.name,
          normalizedPhone: takenPhone,
          source: other.source,
        );
        fail('expected a DuplicatePatientException');
      } on DuplicatePatientException catch (e) {
        expect(e.existing.id, owner.id);
      }

      // Keeping its own number is of course still allowed.
      final sameNumber = await patients(adminPb).update(
        owner.id,
        name: 'Number Owner Renamed',
        normalizedPhone: takenPhone,
        source: owner.source,
      );
      expect(sameNumber.name, 'Number Owner Renamed');
    });

    test('deleting archives the patient — the record and its history survive', () async {
      final patientId = await newPatient(name: 'Patient To Archive');
      final (_, treatmentId) = await consultAndRecommend(patientId);

      await patients(adminPb).archive(patientId);

      // Gone from every list the app shows...
      final listed = await patients(adminPb).listAll();
      expect(listed.map((p) => p.id), isNot(contains(patientId)));
      final counted = await patients(adminPb).counts();
      final visibleIds = (await patients(adminPb).listAll()).map((p) => p.id).toSet();
      expect(counted.total, visibleIds.length);

      // ...but the record itself, and its clinical history, are untouched.
      final archived = await patients(adminPb).getById(patientId);
      expect(archived, isNotNull);
      expect(archived!.archived, isTrue);
      expect(archived.name, 'Patient To Archive');
      final treatments = await TreatmentRepository(adminPb).listForPatient(patientId);
      expect(treatments.map((t) => t.id), contains(treatmentId));
    });

    test('a doctor can neither edit nor delete a patient', () async {
      final patientId = await newPatient(name: 'Doctor Cannot Touch');

      await expectLater(
        patients(doctorAPb).update(
          patientId,
          name: 'Renamed By Doctor',
          normalizedPhone: uniqueTestPhone(),
          source: 'Direct Walk-in',
        ),
        throwsA(isA<ClientException>()),
      );
      await expectLater(
        patients(doctorAPb).archive(patientId),
        throwsA(isA<ClientException>()),
      );

      final untouched = await patients(adminPb).getById(patientId);
      expect(untouched!.name, 'Doctor Cannot Touch');
      expect(untouched.archived, isFalse);
    });

    test('nobody — not even an admin — can hard-delete a patient', () async {
      final patientId = await newPatient(name: 'Never Hard Deleted');

      await expectLater(
        adminPb.collection('patients').delete(patientId),
        throwsA(isA<ClientException>()),
      );
      expect(await patients(adminPb).getById(patientId), isNotNull);
    });
  });

  group('Consultation', () {
    test('records the doctor who submitted it, taken from the session not the request', () async {
      final patientId = await newPatient();
      final consultations = ConsultationRepository(doctorAPb);

      final draft = await consultations.saveDraft(patientId: patientId);
      final completed = await consultations.complete(
        draft.id,
        recommendation: ConsultationRecommendation.noTreatmentRequired,
        notes: 'Nothing required.',
      );

      expect(completed.doctorId, doctorAId);
      expect(completed.isCompleted, isTrue);
      expect(completed.completedAt, isNotNull);
    });

    test('the no-treatment path still supports an optional consultation fee', () async {
      final patientId = await newPatient();
      final consultations = ConsultationRepository(doctorAPb);
      final draft = await consultations.saveDraft(patientId: patientId);

      final completed = await consultations.complete(
        draft.id,
        recommendation: ConsultationRecommendation.noTreatmentRequired,
        notes: 'Advice only.',
        consultationFee: 500,
      );

      expect(completed.recommendedTreatment, isFalse);
      expect(completed.consultationFee, 500);
      expect(completed.treatmentId, isEmpty); // no treatment created
    });

    test('doctor attribution cannot be rewritten afterwards', () async {
      final patientId = await newPatient();
      final consultations = ConsultationRepository(doctorAPb);
      final draft = await consultations.saveDraft(patientId: patientId);
      await consultations.complete(
        draft.id,
        recommendation: ConsultationRecommendation.noTreatmentRequired,
        notes: 'Done.',
      );

      // Even an admin cannot re-attribute it to another doctor.
      await expectLater(
        adminPb.collection('consultations').update(draft.id, body: {'doctor': doctorBId}),
        throwsA(anything),
      );
    });

    test('the treatment path creates a treatment with a package cost', () async {
      final patientId = await newPatient();
      final (consultationId, treatmentId) = await consultAndRecommend(patientId, packageCost: 50000);

      final treatments = await TreatmentRepository(adminPb).listForPatient(patientId);
      final treatment = treatments.firstWhere((t) => t.id == treatmentId);
      expect(treatment.packageCost, 50000);
      expect(treatment.consultationId, consultationId);
      // Total sessions is optional and was not supplied.
      expect(treatment.sessionsTotal, isNull);
    });
  });

  group('Session arrival and completion', () {
    test('Patient Arrived is stamped by the server, and a client cannot forge it', () async {
      final patientId = await newPatient();
      final (_, treatmentId) = await consultAndRecommend(patientId);
      final sessions = SessionRepository(adminPb);
      final session = await sessions.schedule(
        patientId: patientId,
        treatmentId: treatmentId,
        scheduledDate: DateTime.now(),
      );
      expect(session.isAssigned, isFalse, reason: 'doctor is optional at scheduling');

      final arrived = await sessions.markArrived(session.id);
      expect(arrived.status, SessionStatus.arrived);
      expect(arrived.arrivedAt, isNotNull);

      // A crafted request with a bogus arrival time is ignored.
      final tampered = await adminPb.collection('sessions').update(session.id, body: {
        'arrived_at': DateTime.utc(2000, 1, 1).toIso8601String(),
      });
      expect(tampered.getStringValue('arrived_at'), isNot(contains('2000')));
    });

    test('completion requires notes and at least one image', () async {
      final patientId = await newPatient();
      final (_, treatmentId) = await consultAndRecommend(patientId);
      final adminSessions = SessionRepository(adminPb);
      final session = await adminSessions.schedule(
        patientId: patientId,
        treatmentId: treatmentId,
        scheduledDate: DateTime.now(),
      );
      await adminSessions.markArrived(session.id);
      final doctorSessions = SessionRepository(doctorAPb);

      await expectLater(
        doctorSessions.complete(session.id, notes: ''),
        throwsA(isA<SessionCompletionRejected>()),
      );
      await expectLater(
        doctorSessions.complete(session.id, notes: 'Notes but no image'),
        throwsA(isA<SessionCompletionRejected>()),
      );

      await doctorSessions.uploadImages(session.id, [('after.png', testPngBytes)]);
      final completed = await doctorSessions.complete(session.id, notes: 'All good.');
      expect(completed.status, SessionStatus.completed);
      expect(completed.endedAt, isNotNull);
    });

    test('an unassigned session becomes the completing doctor\'s, per session only', () async {
      final patientId = await newPatient();
      final (_, treatmentId) = await consultAndRecommend(patientId);
      final adminSessions = SessionRepository(adminPb);

      // Session 1 — left unassigned, completed by Doctor B.
      final first = await adminSessions.schedule(
        patientId: patientId,
        treatmentId: treatmentId,
        scheduledDate: DateTime.now(),
      );
      await adminSessions.markArrived(first.id);
      await SessionRepository(doctorBPb).uploadImages(first.id, [('a.png', testPngBytes)]);
      final firstDone = await SessionRepository(doctorBPb).complete(first.id, notes: 'Session 1');
      expect(firstDone.doctorId, doctorBId);

      // Session 2 — assigned to Doctor A, completed by Doctor B: the
      // original assignment survives.
      final second = await adminSessions.schedule(
        patientId: patientId,
        treatmentId: treatmentId,
        scheduledDate: DateTime.now(),
        doctorId: doctorAId,
      );
      await adminSessions.markArrived(second.id);
      await SessionRepository(doctorBPb).uploadImages(second.id, [('b.png', testPngBytes)]);
      final secondDone = await SessionRepository(doctorBPb).complete(second.id, notes: 'Session 2');
      expect(secondDone.doctorId, doctorAId);

      // The patient is not bound to either doctor.
      final patientRecord = await adminPb.collection('patients').getOne(patientId);
      expect(patientRecord.getStringValue('assigned_doctor'), isEmpty);
    });

    test('a session cannot be completed before the patient has arrived', () async {
      final patientId = await newPatient();
      final (_, treatmentId) = await consultAndRecommend(patientId);
      final session = await SessionRepository(adminPb).schedule(
        patientId: patientId,
        treatmentId: treatmentId,
        scheduledDate: DateTime.now(),
      );
      await SessionRepository(doctorAPb).uploadImages(session.id, [('x.png', testPngBytes)]);

      await expectLater(
        SessionRepository(doctorAPb).complete(session.id, notes: 'Jumping ahead'),
        throwsA(isA<SessionCompletionRejected>()),
      );
    });

    test('Admin can add session images too, not just the Doctor', () async {
      final patientId = await newPatient();
      final (_, treatmentId) = await consultAndRecommend(patientId);
      final session = await SessionRepository(adminPb).schedule(
        patientId: patientId,
        treatmentId: treatmentId,
        scheduledDate: DateTime.now(),
      );

      final updated = await SessionRepository(adminPb)
          .uploadImages(session.id, [('admin-added.png', testPngBytes)]);

      expect(updated.imageFilenames, hasLength(1));
    });
  });

  group('Automatic no-show', () {
    // The nightly job (pb_hooks/sessions_no_show_cron.pb.js) runs on the
    // server's clock at 23:59 and can't be triggered from here, so what is
    // verified is the exact rule it applies: the same filter must select
    // only genuinely overdue, un-arrived, still-scheduled sessions.
    test('selects only past un-arrived scheduled sessions — not today, future, arrived or completed', () async {
      final patientId = await newPatient();
      final (_, treatmentId) = await consultAndRecommend(patientId);
      final sessions = SessionRepository(adminPb);
      final now = DateTime.now();
      final todayUtc = DateTime.utc(now.year, now.month, now.day);

      final future = await sessions.schedule(
        patientId: patientId, treatmentId: treatmentId,
        scheduledDate: todayUtc.add(const Duration(days: 1)));
      final today = await sessions.schedule(
        patientId: patientId, treatmentId: treatmentId, scheduledDate: todayUtc);
      final overdue = await sessions.schedule(
        patientId: patientId, treatmentId: treatmentId,
        scheduledDate: todayUtc.subtract(const Duration(days: 1)));
      final overdueButArrived = await sessions.schedule(
        patientId: patientId, treatmentId: treatmentId,
        scheduledDate: todayUtc.subtract(const Duration(days: 1)));
      await sessions.markArrived(overdueButArrived.id);

      final todayIso = todayUtc.toIso8601String().replaceFirst('T', ' ');
      final swept = await adminPb.collection('sessions').getFullList(
            filter: 'status = "scheduled" && scheduled_date < "$todayIso"',
          );
      final sweptIds = swept.map((r) => r.id).toSet();

      expect(sweptIds.contains(overdue.id), isTrue);
      expect(sweptIds.contains(today.id), isFalse, reason: 'today is never a no-show');
      expect(sweptIds.contains(future.id), isFalse);
      expect(sweptIds.contains(overdueButArrived.id), isFalse);
    });
  });

  group('Billing and treatment progress', () {
    test('generating a bill does not mark it paid; Patient Paid does', () async {
      final patientId = await newPatient();
      final (consultationId, _) = await consultAndRecommend(patientId, consultationFee: 500);
      final bills = BillRepository(adminPb);

      final bill = await bills.createConsultationBill(
        patientId: patientId,
        consultationId: consultationId,
        consultationFee: 500,
        paymentMethod: PaymentMethod.cash,
      );
      expect(bill.isPaid, isFalse);
      expect(bill.paidAt, isNull);

      final paid = await bills.markPaid(bill.id);
      expect(paid.isPaid, isTrue);
      expect(paid.paidAt, isNotNull, reason: 'stamped server-side');
    });

    test('a client cannot forge paid_at without actually paying', () async {
      final patientId = await newPatient();
      final (consultationId, _) = await consultAndRecommend(patientId);
      final bill = await BillRepository(adminPb).createConsultationBill(
        patientId: patientId,
        consultationId: consultationId,
        consultationFee: 500,
        paymentMethod: PaymentMethod.cash,
      );

      final tampered = await adminPb.collection('bills').update(bill.id, body: {
        'paid_at': DateTime.utc(2000, 1, 1).toIso8601String(),
      });

      expect(tampered.getStringValue('paid_at'), isEmpty);
      expect(tampered.getStringValue('payment_status'), 'Pending');
    });

    test('a paid session bill drives progress; product and consultation fee do not', () async {
      final patientId = await newPatient();
      final (consultationId, treatmentId) = await consultAndRecommend(patientId, packageCost: 50000);
      final bills = BillRepository(adminPb);
      final sessions = SessionRepository(adminPb);

      // A paid consultation bill — must not count toward progress.
      final consultationBill = await bills.createConsultationBill(
        patientId: patientId,
        consultationId: consultationId,
        consultationFee: 1500,
        paymentMethod: PaymentMethod.cash,
      );
      await bills.markPaid(consultationBill.id);

      final session = await sessions.schedule(
        patientId: patientId, treatmentId: treatmentId, scheduledDate: DateTime.now());
      final sessionBill = await bills.createSessionBill(
        patientId: patientId,
        sessionId: session.id,
        treatmentId: treatmentId,
        sessionFee: 10000,
        productName: 'Serum',
        productCost: 2000,
        paymentMethod: PaymentMethod.online,
      );

      // Before Patient Paid: no progress at all.
      final treatment = (await TreatmentRepository(adminPb).listForPatient(patientId))
          .firstWhere((t) => t.id == treatmentId);
      var progress = treatmentProgressFrom(treatment, await bills.listForPatient(patientId));
      expect(progress.percent, 0);

      await bills.markPaid(sessionBill.id);
      progress = treatmentProgressFrom(treatment, await bills.listForPatient(patientId));

      // ₹10,000 of ₹50,000 — the ₹2,000 product and ₹1,500 consultation
      // fee are both excluded.
      expect(progress.paidAmount, 10000);
      expect(progress.percent, 20);
    });

    test('editing the fee down before Patient Paid records a partial payment', () async {
      final patientId = await newPatient();
      final (_, treatmentId) = await consultAndRecommend(patientId, packageCost: 50000);
      final bills = BillRepository(adminPb);
      final session = await SessionRepository(adminPb).schedule(
        patientId: patientId, treatmentId: treatmentId, scheduledDate: DateTime.now());

      final bill = await bills.createSessionBill(
        patientId: patientId,
        sessionId: session.id,
        treatmentId: treatmentId,
        sessionFee: 10000,
        paymentMethod: PaymentMethod.cash,
      );
      // Patient only pays ₹5,000.
      await bills.updateAmounts(bill.id, sessionFee: 5000, paymentMethod: PaymentMethod.online);
      await bills.markPaid(bill.id);

      final treatment = (await TreatmentRepository(adminPb).listForPatient(patientId))
          .firstWhere((t) => t.id == treatmentId);
      final progress = treatmentProgressFrom(treatment, await bills.listForPatient(patientId));

      expect(progress.paidAmount, 5000);
      expect(progress.percent, 10);
    });

    test('a suggested product from consultation never lands on a session bill', () async {
      final patientId = await newPatient();
      final (consultationId, treatmentId) = await consultAndRecommend(patientId);
      final consultation = await ConsultationRepository(adminPb).getById(consultationId);
      expect(consultation!.suggestedProduct, 'Serum A');

      final session = await SessionRepository(adminPb).schedule(
        patientId: patientId, treatmentId: treatmentId, scheduledDate: DateTime.now());
      final sessionBill = await BillRepository(adminPb).createSessionBill(
        patientId: patientId,
        sessionId: session.id,
        treatmentId: treatmentId,
        sessionFee: 10000,
        paymentMethod: PaymentMethod.cash,
      );

      expect(sessionBill.productName, isEmpty);
      expect(sessionBill.productCost, 0);
    });
  });

  group('Treatment plan configuration', () {
    test('admin configures plans; deactivating hides them from new selection only', () async {
      final repo = TreatmentPlanRepository(adminPb);
      final name = 'Hair PRP ${DateTime.now().microsecondsSinceEpoch}';

      final plan = await repo.create(category: TreatmentCategory.hair, name: name);
      expect(plan.active, isTrue);
      expect(
        (await repo.listActiveForCategory(TreatmentCategory.hair)).any((p) => p.id == plan.id),
        isTrue,
      );

      await repo.setActive(plan.id, false);
      expect(
        (await repo.listActiveForCategory(TreatmentCategory.hair)).any((p) => p.id == plan.id),
        isFalse,
      );
      // Still present for the management screen — deactivated, not deleted.
      expect((await repo.listAll()).any((p) => p.id == plan.id && !p.active), isTrue);
    });

    test('a doctor can read plans but cannot configure them', () async {
      final doctorRepo = TreatmentPlanRepository(doctorAPb);
      await doctorRepo.listActiveForCategory(TreatmentCategory.hair); // no throw

      await expectLater(
        doctorAPb.collection('treatment_plans').create(body: {
          'category': TreatmentCategory.hair,
          'name': 'Not allowed',
          'active': true,
        }),
        throwsA(anything),
      );
    });
  });
}
