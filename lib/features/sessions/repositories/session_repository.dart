import 'package:http/http.dart' as http;
import 'package:pocketbase/pocketbase.dart';

import '../../../core/directory/doctor_directory.dart';
import '../models/session.dart';

/// Thrown when the server refuses a completion for a business reason
/// (missing notes/images, or the patient never arrived). The hook is
/// authoritative; this just surfaces its message distinctly.
class SessionCompletionRejected implements Exception {
  final String message;
  SessionCompletionRejected(this.message);
}

/// Sessions are DATE ONLY — no appointment time slots — and their doctor is
/// optional throughout. Arrival and completion timestamps come from the
/// server (pb_hooks/sessions_workflow.pb.js), never from this client.
class SessionRepository {
  SessionRepository(this._pb);

  final PocketBase _pb;

  RecordService get _collection => _pb.collection('sessions');

  String get _authenticatedUserId {
    final id = _pb.authStore.record?.id;
    if (id == null) {
      throw StateError('No authenticated user — cannot act on a session.');
    }
    return id;
  }

  /// Date-only: written as UTC midnight so no local/UTC conversion can
  /// shift the calendar date, and so the no-show job can compare dates.
  static String _isoDate(DateTime d) =>
      DateTime.utc(d.year, d.month, d.day).toIso8601String();

  Future<List<DoctorOption>> listDoctors() => listActiveDoctors(_pb);

  Future<List<Session>> listForPatient(String patientId) async {
    final records = await _collection.getFullList(
      filter: 'patient = "$patientId"',
      sort: '-scheduled_date',
      expand: 'doctor,patient',
    );
    return records.map(Session.fromRecord).toList();
  }

  Future<Session?> getById(String id) async {
    try {
      return Session.fromRecord(await _collection.getOne(id, expand: 'doctor,patient'));
    } catch (_) {
      return null;
    }
  }

  /// Everything booked for today — the Admin's Today's Schedule and the
  /// Doctor's Today's Sessions are both built from this.
  Future<List<Session>> listToday({DateTime? now}) async {
    final today = now ?? DateTime.now();
    final start = _isoDate(today);
    final end = _isoDate(today.add(const Duration(days: 1)));
    final records = await _collection.getFullList(
      filter: 'scheduled_date >= "$start" && scheduled_date < "$end"',
      sort: 'scheduled_date',
      expand: 'doctor,patient',
    );
    return records.map(Session.fromRecord).toList();
  }

  /// Patients who have arrived and are waiting for a doctor.
  Future<List<Session>> listArrived() async {
    final records = await _collection.getFullList(
      filter: 'status = "arrived"',
      sort: 'arrived_at',
      expand: 'doctor,patient',
    );
    return records.map(Session.fromRecord).toList();
  }

  /// Sessions already swept to no-show — the Admin dashboard's follow-up
  /// list. Deliberately NOT the Telecaller follow-up rule.
  Future<List<Session>> listNoShow({int limit = 50}) async {
    final results = await _collection.getList(
      page: 1,
      perPage: limit,
      filter: 'status = "no_show"',
      sort: '-scheduled_date',
      expand: 'doctor,patient',
    );
    return results.items.map(Session.fromRecord).toList();
  }

  Uri imageUrl(Session session, String filename) {
    return _pb.files.getURL(
      RecordModel.fromJson({
        'id': session.id,
        'collectionId': 'sessions',
        'collectionName': 'sessions',
      }),
      filename,
    );
  }

  /// [doctorId] is optional — leaving it out means any authorized doctor
  /// can take the session.
  Future<Session> schedule({
    required String patientId,
    required String treatmentId,
    required DateTime scheduledDate,
    String? doctorId,
  }) async {
    final record = await _collection.create(body: {
      'patient': patientId,
      'treatment': treatmentId,
      if (doctorId != null && doctorId.isNotEmpty) 'doctor': doctorId,
      'scheduled_date': _isoDate(scheduledDate),
      'status': 'scheduled',
      'created_by': _authenticatedUserId,
    });
    return Session.fromRecord(record);
  }

  /// Reschedules by DATE only.
  Future<Session> reschedule(String id, DateTime newDate) async {
    final record = await _collection.update(id, body: {
      'scheduled_date': _isoDate(newDate),
      'status': 'scheduled',
    });
    return Session.fromRecord(record);
  }

  /// "Patient Arrived". The arrival time is stamped by the SERVER — the
  /// value is never sent from here. [doctorId] optionally assigns a doctor
  /// at this point; omitting it leaves the session open to any doctor.
  Future<Session> markArrived(String id, {String? doctorId}) async {
    final record = await _collection.update(id, body: {
      'status': 'arrived',
      if (doctorId != null && doctorId.isNotEmpty) 'doctor': doctorId,
    });
    return Session.fromRecord(record);
  }

  Future<Session> assignDoctor(String id, String? doctorId) async {
    final record = await _collection.update(id, body: {'doctor': doctorId ?? ''});
    return Session.fromRecord(record);
  }

  /// Saves clinical work in progress without completing the session.
  Future<Session> saveNotes(String id, {required String notes, DateTime? followUpDate}) async {
    final record = await _collection.update(id, body: {
      'notes': notes,
      if (followUpDate != null) 'follow_up_date': _isoDate(followUpDate),
    });
    return Session.fromRecord(record);
  }

  /// Both Admin and Doctor may add session images.
  Future<Session> uploadImages(String id, List<(String filename, List<int> bytes)> files) async {
    final record = await _collection.update(
      id,
      files: [
        for (final (filename, bytes) in files)
          http.MultipartFile.fromBytes('images', bytes, filename: filename),
      ],
    );
    return Session.fromRecord(record);
  }

  /// "Session Completed" — the only completion action; there is no Start
  /// Session or End Session. The server validates the required clinical
  /// information, stamps the completion time and assigns the completing
  /// doctor if the session was unassigned.
  Future<Session> complete(
    String id, {
    required String notes,
    DateTime? followUpDate,
  }) async {
    try {
      final record = await _collection.update(id, body: {
        'status': 'completed',
        'notes': notes,
        if (followUpDate != null) 'follow_up_date': _isoDate(followUpDate),
      });
      return Session.fromRecord(record);
    } on ClientException catch (e) {
      final message = e.response['message'];
      throw SessionCompletionRejected(
        message is String && message.isNotEmpty ? message : 'Could not complete the session.',
      );
    }
  }
}
