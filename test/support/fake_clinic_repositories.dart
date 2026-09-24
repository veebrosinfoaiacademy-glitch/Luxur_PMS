import 'package:pocketbase/pocketbase.dart';
import 'package:pms_vbis/features/billing/models/bill.dart';
import 'package:pms_vbis/features/billing/repositories/bill_repository.dart';
import 'package:pms_vbis/features/consultations/models/consultation.dart';
import 'package:pms_vbis/features/consultations/repositories/consultation_repository.dart';
import 'package:pms_vbis/features/patients/models/patient.dart';
import 'package:pms_vbis/features/patients/repositories/patient_repository.dart';
import 'package:pms_vbis/features/sessions/models/session.dart';
import 'package:pms_vbis/features/sessions/repositories/session_repository.dart';
import 'package:pms_vbis/features/telecaller/repositories/telecaller_lead_repository.dart';
import 'package:pms_vbis/features/treatments/models/treatment.dart';
import 'package:pms_vbis/features/treatments/repositories/treatment_repository.dart';

/// In-memory stand-ins for the clinic repositories.
///
/// Widget tests run under TestWidgetsFlutterBinding, which turns every HTTP
/// request into a 400, so the dashboards have to be fed from fakes rather
/// than the real backend. The backend rules themselves are covered
/// end-to-end in test/admin_workflow.
final _unusedPb = PocketBase('http://127.0.0.1:1');

Patient fakePatient({
  required String id,
  required String name,
  String code = 'PT-1000',
  String phone = '9876500000',
  DateTime? created,
}) {
  return Patient(
    id: id,
    patientCode: code,
    name: name,
    gender: 'Female',
    phone: phone,
    address: '',
    source: 'Direct Walk-in',
    referralName: '',
    concern: '',
    telecallerLeadId: '',
    telecallerId: '',
    status: 'Joined',
    archived: false,
    createdById: '',
    created: created ?? DateTime.now(),
  );
}

Session fakeSession({
  required String id,
  required String patientId,
  required String patientName,
  String patientCode = 'PT-1000',
  String patientPhone = '9876500000',
  String doctorId = '',
  String? doctorName,
  DateTime? scheduledDate,
  SessionStatus status = SessionStatus.scheduled,
}) {
  return Session(
    id: id,
    patientId: patientId,
    patientName: patientName,
    patientCode: patientCode,
    patientPhone: patientPhone,
    treatmentId: 'treatment-1',
    doctorId: doctorId,
    doctorName: doctorName,
    scheduledDate: scheduledDate ?? DateTime.now(),
    status: status,
    notes: '',
    imageFilenames: const [],
    created: DateTime.now(),
  );
}

class FakePatientRepository extends PatientRepository {
  FakePatientRepository({
    this.registeredToday = const [],
    this.all = const [],
    this.total = 0,
    this.joined = 0,
    this.profile,
  }) : super(_unusedPb, TelecallerLeadRepository(_unusedPb));

  final List<Patient> registeredToday;
  final List<Patient> all;
  final int total;
  final int joined;

  /// The patient a profile test opens.
  final Patient? profile;

  /// What the UI asked to archive — the app's "delete".
  final List<String> archived = [];

  /// The details an edit sent, so a test can assert what was saved without
  /// reaching a real backend.
  final List<({String id, String name, String phone})> updates = [];

  @override
  Future<List<Patient>> listRegisteredToday({DateTime? now}) async => registeredToday;

  @override
  Future<List<Patient>> listAll() async => all;

  @override
  Future<({int joined, int total})> counts() async => (total: total, joined: joined);

  @override
  Future<Patient?> getById(String id) async => profile;

  @override
  Future<Patient?> findByPhone(String normalizedPhone) async => null;

  @override
  Future<Patient> update(
    String id, {
    required String name,
    required String normalizedPhone,
    required String source,
    int? age,
    String gender = '',
    String address = '',
    String referralName = '',
    String concern = '',
  }) async {
    updates.add((id: id, name: name, phone: normalizedPhone));
    return profile!;
  }

  @override
  Future<Patient> archive(String id) async {
    archived.add(id);
    return profile!;
  }
}

class FakeConsultationRepository extends ConsultationRepository {
  FakeConsultationRepository({this.seenPatientIds = const {}}) : super(_unusedPb);

  final Set<String> seenPatientIds;

  @override
  Future<Set<String>> patientIdsWithCompletedConsultation(List<String> patientIds) async =>
      seenPatientIds.intersection(patientIds.toSet());

  @override
  Future<List<Consultation>> listForPatient(String patientId) async => const [];
}

class FakeTreatmentRepository extends TreatmentRepository {
  FakeTreatmentRepository() : super(_unusedPb);

  @override
  Future<List<Treatment>> listForPatient(String patientId) async => const [];
}

class FakeSessionRepository extends SessionRepository {
  FakeSessionRepository({this.today = const [], this.noShow = const []})
      : super(_unusedPb);

  final List<Session> today;
  final List<Session> noShow;

  @override
  Future<List<Session>> listForPatient(String patientId) async => const [];

  /// Records what the UI asked to mark as arrived, so a test can assert the
  /// action reached the repository without going near a real clock.
  final List<String> markedArrived = [];

  @override
  Future<List<Session>> listToday({DateTime? now}) async => today;

  @override
  Future<List<Session>> listNoShow({int limit = 50}) async => noShow;

  @override
  Future<Session> markArrived(String id, {String? doctorId}) async {
    markedArrived.add(id);
    return today.firstWhere((s) => s.id == id);
  }
}

class FakeBillRepository extends BillRepository {
  FakeBillRepository({this.bills = const []}) : super(_unusedPb);

  final List<Bill> bills;

  @override
  Future<List<Bill>> listForPatient(String patientId) async =>
      bills.where((b) => b.patientId == patientId).toList();
}
