import 'package:pocketbase/pocketbase.dart';

/// Mirrors the `patients` PocketBase collection
/// (pocketbase/pb_migrations/1700000004_create_patients.js).
///
/// Note there is deliberately NO doctor on a patient: doctor attribution
/// belongs to each clinical record (consultation / session), never to the
/// patient. The collection's legacy `assigned_doctor` field is not read or
/// written by this app.
class Patient {
  final String id;
  final String patientCode;
  final String name;
  final int? age;
  final String gender;
  final String phone;
  final String address;
  final String source;
  /// Only meaningful when [source] is 'Doctor Recommendation'.
  final String referralName;
  final String concern;
  /// Set only when this patient came from converting a Telecaller lead —
  /// attribution that must never be lost.
  final String telecallerLeadId;
  final String telecallerId;
  final String? telecallerName;
  final String status;
  final bool archived;
  final String createdById;
  final DateTime created;

  const Patient({
    required this.id,
    required this.patientCode,
    required this.name,
    this.age,
    required this.gender,
    required this.phone,
    required this.address,
    required this.source,
    required this.referralName,
    required this.concern,
    required this.telecallerLeadId,
    required this.telecallerId,
    this.telecallerName,
    required this.status,
    required this.archived,
    required this.createdById,
    required this.created,
  });

  bool get isFromTelecallerLead => telecallerLeadId.isNotEmpty;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'P';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  factory Patient.fromRecord(RecordModel r) {
    // An age that was never entered — or one cleared on an edit — comes
    // back from PocketBase as 0 rather than as an absent value, and nobody
    // is 0 years old.
    final rawAge = r.getStringValue('age');
    final parsedAge = rawAge.isEmpty ? null : int.tryParse(rawAge);
    final telecallerRecord = r.get<RecordModel?>('expand.telecaller', null);
    return Patient(
      id: r.id,
      patientCode: r.getStringValue('patient_code'),
      name: r.getStringValue('name'),
      age: (parsedAge == null || parsedAge <= 0) ? null : parsedAge,
      gender: r.getStringValue('gender'),
      phone: r.getStringValue('phone'),
      address: r.getStringValue('address'),
      source: r.getStringValue('source'),
      referralName: r.getStringValue('referral_name'),
      concern: r.getStringValue('concern'),
      telecallerLeadId: r.getStringValue('telecaller_lead'),
      telecallerId: r.getStringValue('telecaller'),
      telecallerName: telecallerRecord?.getStringValue('name'),
      status: r.getStringValue('status'),
      archived: r.getBoolValue('archived'),
      createdById: r.getStringValue('created_by'),
      created: DateTime.tryParse(r.getStringValue('created')) ?? DateTime.now(),
    );
  }
}

/// The canonical Source options — matches the `patients.source` select
/// exactly (pocketbase/pb_migrations/1700000004_create_patients.js).
class PatientSource {
  PatientSource._();
  static const directWalkIn = 'Direct Walk-in';
  static const googleAd = 'Google Ad';
  static const metaAd = 'Meta Ad';
  static const doctorRecommendation = 'Doctor Recommendation';
  static const telecalling = 'Telecalling';

  static const all = [directWalkIn, googleAd, metaAd, doctorRecommendation, telecalling];
}
