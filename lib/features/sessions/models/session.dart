import 'package:pocketbase/pocketbase.dart';

/// The finalized session states. There is no "in progress" in this
/// workflow — a session goes straight from ARRIVED to COMPLETED, with no
/// Start Session step. `in_progress` remains a legal value at the schema
/// level only so rows written by the previous implementation still load;
/// nothing in this app writes it.
enum SessionStatus { scheduled, arrived, completed, noShow, rescheduled, inProgressLegacy }

extension SessionStatusX on SessionStatus {
  String get raw => switch (this) {
        SessionStatus.scheduled => 'scheduled',
        SessionStatus.arrived => 'arrived',
        SessionStatus.completed => 'completed',
        SessionStatus.noShow => 'no_show',
        SessionStatus.rescheduled => 'rescheduled',
        SessionStatus.inProgressLegacy => 'in_progress',
      };

  String get label => switch (this) {
        SessionStatus.scheduled => 'Scheduled',
        SessionStatus.arrived => 'Waiting for Session',
        SessionStatus.completed => 'Completed',
        SessionStatus.noShow => 'No-Show',
        SessionStatus.rescheduled => 'Rescheduled',
        SessionStatus.inProgressLegacy => 'In Progress',
      };

  static SessionStatus fromRaw(String raw) => switch (raw) {
        'scheduled' => SessionStatus.scheduled,
        'arrived' => SessionStatus.arrived,
        'completed' => SessionStatus.completed,
        'no_show' => SessionStatus.noShow,
        'rescheduled' => SessionStatus.rescheduled,
        _ => SessionStatus.inProgressLegacy,
      };
}

/// Mirrors `sessions` (pocketbase/pb_migrations/1700000007_create_sessions.js,
/// 1700000008, 1700000013).
///
/// Scheduling is DATE ONLY — there are no appointment time slots; a patient
/// may arrive at any time on [scheduledDate]. [doctorId] is optional and
/// applies to THIS session alone.
class Session {
  final String id;
  final String patientId;
  final String? patientName;
  final String? patientCode;
  /// Carried on the expanded patient so the no-show list can offer a Call
  /// action without a second fetch per row.
  final String? patientPhone;
  final String treatmentId;
  /// Empty when the session is unassigned — any authorized doctor may take
  /// it, and whoever completes it becomes this session's doctor.
  final String doctorId;
  final String? doctorName;
  final DateTime scheduledDate;
  final SessionStatus status;
  /// Server-stamped (pb_hooks/sessions_workflow.pb.js) — never the client's
  /// device clock.
  final DateTime? arrivedAt;
  final DateTime? endedAt;
  final DateTime? followUpDate;
  final String notes;
  final List<String> imageFilenames;
  final DateTime created;

  const Session({
    required this.id,
    required this.patientId,
    this.patientName,
    this.patientCode,
    this.patientPhone,
    required this.treatmentId,
    required this.doctorId,
    this.doctorName,
    required this.scheduledDate,
    required this.status,
    this.arrivedAt,
    this.endedAt,
    this.followUpDate,
    required this.notes,
    required this.imageFilenames,
    required this.created,
  });

  bool get isAssigned => doctorId.isNotEmpty;
  bool get hasArrived => status == SessionStatus.arrived;

  factory Session.fromRecord(RecordModel r) {
    final doctorRecord = r.get<RecordModel?>('expand.doctor', null);
    final patientRecord = r.get<RecordModel?>('expand.patient', null);
    final rawArrived = r.getStringValue('arrived_at');
    final rawEnded = r.getStringValue('ended_at');
    final rawFollowUp = r.getStringValue('follow_up_date');
    return Session(
      id: r.id,
      patientId: r.getStringValue('patient'),
      patientName: patientRecord?.getStringValue('name'),
      patientCode: patientRecord?.getStringValue('patient_code'),
      patientPhone: patientRecord?.getStringValue('phone'),
      treatmentId: r.getStringValue('treatment'),
      doctorId: r.getStringValue('doctor'),
      doctorName: doctorRecord?.getStringValue('name'),
      scheduledDate: DateTime.tryParse(r.getStringValue('scheduled_date')) ?? DateTime.now(),
      status: SessionStatusX.fromRaw(r.getStringValue('status')),
      arrivedAt: rawArrived.isEmpty ? null : DateTime.tryParse(rawArrived),
      endedAt: rawEnded.isEmpty ? null : DateTime.tryParse(rawEnded),
      followUpDate: rawFollowUp.isEmpty ? null : DateTime.tryParse(rawFollowUp),
      notes: r.getStringValue('notes'),
      imageFilenames: r.getListValue<String>('images'),
      created: DateTime.tryParse(r.getStringValue('created')) ?? DateTime.now(),
    );
  }
}
