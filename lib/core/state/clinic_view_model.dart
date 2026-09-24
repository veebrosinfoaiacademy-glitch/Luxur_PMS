import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../features/billing/models/bill.dart';
import '../../features/billing/repositories/bill_repository.dart';
import '../../features/consultations/models/consultation.dart';
import '../../features/consultations/repositories/consultation_repository.dart';
import '../../features/patients/models/patient.dart';
import '../../features/patients/repositories/patient_repository.dart';
import '../../features/sessions/models/session.dart';
import '../../features/sessions/repositories/session_repository.dart';
import '../../features/telecaller/repositories/telecaller_lead_repository.dart';
import '../../features/treatments/models/treatment.dart';
import '../../features/treatments/repositories/treatment_plan_repository.dart';
import '../../features/treatments/repositories/treatment_repository.dart';
import '../../features/treatments/utils/treatment_progress.dart';
import '../directory/doctor_directory.dart';

/// One line in Today's Schedule. A patient waiting for a consultation has
/// no session yet, so [session] is null for those rows and set for the
/// treatment-session rows.
class ScheduleEntry {
  final Patient patient;
  final Session? session;

  /// Only meaningful on a consultation row: whether a doctor has already
  /// completed that patient's consultation today.
  final bool consultationCompleted;

  const ScheduleEntry({
    required this.patient,
    this.session,
    this.consultationCompleted = false,
  });

  bool get isConsultation => session == null;

  /// Deliberately the workflow's own wording — "Waiting for Consultation"
  /// is the state of a registered patient no doctor has seen yet.
  String get statusLabel => session == null
      ? (consultationCompleted ? 'Consultation Completed' : 'Waiting for Consultation')
      : session!.status.label;

  bool get isDone =>
      consultationCompleted || session?.status == SessionStatus.completed;
}

/// Everything the Patient Profile tabs read, fetched once per patient so
/// the six tabs don't each issue their own queries.
class PatientProfile {
  final Patient patient;
  final List<Consultation> consultations;
  final List<Treatment> treatments;
  final List<Session> sessions;
  final List<Bill> bills;

  const PatientProfile({
    required this.patient,
    required this.consultations,
    required this.treatments,
    required this.sessions,
    required this.bills,
  });

  /// A patient registered but never seen shows only Patient Information
  /// and Notes — there is no clinical history to show yet.
  bool get hasClinicalHistory =>
      consultations.isNotEmpty || treatments.isNotEmpty || sessions.isNotEmpty;

  List<Session> sessionsFor(String treatmentId) =>
      sessions.where((s) => s.treatmentId == treatmentId).toList();

  TreatmentProgress progressFor(Treatment treatment) =>
      treatmentProgressFrom(treatment, bills);
}

/// The clinical state shared by the Admin and Doctor shells.
///
/// Everything here is real data from PocketBase — the mock [AppViewModel]
/// remains only for the Pharmacy Bills screens, which are out of scope.
class ClinicViewModel extends ChangeNotifier {
  ClinicViewModel({
    required PocketBase pb,
    required this.role,
    required this.displayName,
    PatientRepository? patients,
    ConsultationRepository? consultations,
    TreatmentRepository? treatments,
    SessionRepository? sessions,
    BillRepository? bills,
    TreatmentPlanRepository? treatmentPlans,
  })  : _pb = pb,
        patients = patients ?? PatientRepository(pb, TelecallerLeadRepository(pb)),
        consultations = consultations ?? ConsultationRepository(pb),
        treatments = treatments ?? TreatmentRepository(pb),
        sessions = sessions ?? SessionRepository(pb),
        bills = bills ?? BillRepository(pb),
        treatmentPlans = treatmentPlans ?? TreatmentPlanRepository(pb);

  final PocketBase _pb;
  final String role;
  final String displayName;

  final PatientRepository patients;
  final ConsultationRepository consultations;
  final TreatmentRepository treatments;
  final SessionRepository sessions;
  final BillRepository bills;
  final TreatmentPlanRepository treatmentPlans;

  bool get isDoctor => role == 'doctor';

  // ---------------------------------------------------------------- dashboard

  bool _loading = false;
  String? _error;
  List<ScheduleEntry> _awaitingConsultation = const [];
  List<Session> _todaysSessions = const [];
  List<ScheduleEntry> _completedToday = const [];
  List<Session> _noShows = const [];
  List<DoctorOption> _doctors = const [];

  bool get isLoading => _loading;
  String? get error => _error;

  /// Newest registration first — a patient who just walked in appears at
  /// the top of the Doctor's list.
  List<ScheduleEntry> get awaitingConsultation => _awaitingConsultation;

  /// Today's treatment sessions still to happen, arrived patients first so
  /// whoever is physically waiting is at the top.
  List<ScheduleEntry> get awaitingSession {
    final open = _todaysSessions
        .where((s) =>
            s.status == SessionStatus.arrived || s.status == SessionStatus.scheduled)
        .toList()
      ..sort((a, b) {
        if (a.hasArrived != b.hasArrived) return a.hasArrived ? -1 : 1;
        return a.created.compareTo(b.created);
      });
    return open.map(_entryForSession).toList();
  }

  List<ScheduleEntry> get completedToday => _completedToday;

  /// Missed appointments, swept overnight by the server's no-show job.
  /// Separate from anything the Telecaller follows up on.
  List<Session> get noShows => _noShows;

  List<DoctorOption> get doctors => _doctors;

  int _totalPatients = 0;
  int _joinedPatients = 0;

  int get totalPatients => _totalPatients;
  int get joinedPatients => _joinedPatients;
  int get notJoinedPatients => _totalPatients - _joinedPatients;

  int get todaysPatientCount =>
      _awaitingConsultation.length + awaitingSession.length + _completedToday.length;

  ScheduleEntry _entryForSession(Session session) {
    return ScheduleEntry(
      patient: _placeholderPatientFor(session),
      session: session,
    );
  }

  /// Sessions arrive with their patient expanded, which is all a schedule
  /// row shows; this avoids a second fetch per row.
  Patient _placeholderPatientFor(Session session) {
    return Patient(
      id: session.patientId,
      patientCode: session.patientCode ?? '',
      name: session.patientName ?? 'Patient',
      gender: '',
      phone: session.patientPhone ?? '',
      address: '',
      source: '',
      referralName: '',
      concern: '',
      telecallerLeadId: '',
      telecallerId: '',
      status: '',
      archived: false,
      createdById: '',
      created: session.created,
    );
  }

  Future<void> refreshDashboard() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final todaysPatients = await patients.listRegisteredToday();
      final seen = await consultations.patientIdsWithCompletedConsultation(
        todaysPatients.map((p) => p.id).toList(),
      );
      final todaysSessions = await sessions.listToday();
      final noShows = await sessions.listNoShow();
      final counts = await patients.counts();

      _awaitingConsultation = todaysPatients
          .where((p) => !seen.contains(p.id))
          .map((p) => ScheduleEntry(patient: p))
          .toList();
      _todaysSessions = todaysSessions;
      _completedToday = [
        ...todaysPatients
            .where((p) => seen.contains(p.id))
            .map((p) => ScheduleEntry(patient: p, consultationCompleted: true)),
        ...todaysSessions
            .where((s) => s.status == SessionStatus.completed)
            .map(_entryForSession),
      ];
      _noShows = noShows;
      _totalPatients = counts.total;
      _joinedPatients = counts.joined;
    } catch (e) {
      _error = _readableError(e);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadDoctors() async {
    if (_doctors.isNotEmpty) return;
    try {
      _doctors = await listActiveDoctors(_pb);
      notifyListeners();
    } catch (_) {
      // A missing doctor list only means the optional picker stays empty —
      // sessions do not require a doctor.
    }
  }

  // ------------------------------------------------------------- patient list

  List<Patient> _allPatients = const [];
  bool _patientsLoading = false;

  List<Patient> get allPatients => _allPatients;
  bool get isPatientsLoading => _patientsLoading;

  Future<void> loadPatients() async {
    _patientsLoading = true;
    notifyListeners();
    try {
      _allPatients = await patients.listAll();
    } catch (e) {
      _error = _readableError(e);
    } finally {
      _patientsLoading = false;
      notifyListeners();
    }
  }

  // ------------------------------------------------------------------ profile

  PatientProfile? _profile;
  bool _profileLoading = false;

  PatientProfile? get profile => _profile;
  bool get isProfileLoading => _profileLoading;

  Future<void> openPatient(String patientId) async {
    _profileLoading = true;
    _profile = null;
    notifyListeners();
    await _reloadProfile(patientId);
  }

  /// Re-reads the open patient after any action that changes their record.
  Future<void> reloadProfile() async {
    final id = _profile?.patient.id;
    if (id == null) return;
    await _reloadProfile(id);
  }

  Future<void> _reloadProfile(String patientId) async {
    try {
      final patient = await patients.getById(patientId);
      if (patient == null) {
        _error = 'That patient could not be loaded.';
        return;
      }
      _profile = PatientProfile(
        patient: patient,
        consultations: await consultations.listForPatient(patientId),
        treatments: await treatments.listForPatient(patientId),
        sessions: await sessions.listForPatient(patientId),
        bills: await bills.listForPatient(patientId),
      );
    } catch (e) {
      _error = _readableError(e);
    } finally {
      _profileLoading = false;
      notifyListeners();
    }
  }

  void closePatient() {
    _profile = null;
    notifyListeners();
  }

  // ------------------------------------------------------------------ actions

  /// "Patient Arrived". The time itself is stamped by the server.
  Future<void> markArrived(String sessionId) async {
    await sessions.markArrived(sessionId);
    await Future.wait([refreshDashboard(), reloadProfile()]);
  }

  Future<void> markBillPaid(String billId) async {
    await bills.markPaid(billId);
    await reloadProfile();
  }

  /// Archives a patient — the app's "delete". Nothing is destroyed, so the
  /// profile is simply closed and the lists re-read without them.
  Future<void> archivePatient(String patientId) async {
    await patients.archive(patientId);
    _profile = null;
    notifyListeners();
    await Future.wait([loadPatients(), refreshDashboard()]);
  }

  static String _readableError(Object e) {
    if (e is ClientException) {
      final message = e.response['message'];
      if (message is String && message.isNotEmpty) return message;
    }
    return 'Something went wrong. Please try again.';
  }
}
