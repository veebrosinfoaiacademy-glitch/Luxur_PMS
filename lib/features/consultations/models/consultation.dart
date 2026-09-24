import 'package:pocketbase/pocketbase.dart';

/// What the Doctor concluded at the end of a consultation.
enum ConsultationRecommendation { recommendTreatment, noTreatmentRequired }

extension ConsultationRecommendationX on ConsultationRecommendation {
  String get raw => switch (this) {
        ConsultationRecommendation.recommendTreatment => 'Recommend Treatment',
        ConsultationRecommendation.noTreatmentRequired => 'No Treatment Required',
      };

  String get label => raw;

  static ConsultationRecommendation? fromRaw(String raw) => switch (raw) {
        'Recommend Treatment' => ConsultationRecommendation.recommendTreatment,
        'No Treatment Required' => ConsultationRecommendation.noTreatmentRequired,
        _ => null,
      };
}

/// Mirrors the `consultations` collection
/// (pocketbase/pb_migrations/1700000014_create_consultations.js).
///
/// The [doctorId] here is the doctor who performed this consultation, and
/// it is pinned server-side (pb_hooks/consultations_workflow.pb.js). It is
/// attribution for THIS record only — the patient is never bound to that
/// doctor, and later sessions may be handled by different doctors.
class Consultation {
  final String id;
  final String patientId;
  final String doctorId;
  final String? doctorName;
  final String reasonForVisit;
  final String notes;
  final List<String> imageFilenames;
  final ConsultationRecommendation? recommendation;
  /// Optional on BOTH paths (treatment and no-treatment). Billed
  /// separately and never counted toward treatment progress.
  final double? consultationFee;
  /// Advisory only — deliberately never carried into session billing.
  final String suggestedProduct;
  final String treatmentId;
  final String status;
  final DateTime? completedAt;
  final DateTime created;

  const Consultation({
    required this.id,
    required this.patientId,
    required this.doctorId,
    this.doctorName,
    required this.reasonForVisit,
    required this.notes,
    required this.imageFilenames,
    this.recommendation,
    this.consultationFee,
    required this.suggestedProduct,
    required this.treatmentId,
    required this.status,
    this.completedAt,
    required this.created,
  });

  bool get isCompleted => status == 'completed';
  bool get recommendedTreatment =>
      recommendation == ConsultationRecommendation.recommendTreatment;

  factory Consultation.fromRecord(RecordModel r) {
    final doctorRecord = r.get<RecordModel?>('expand.doctor', null);
    final rawFee = r.data['consultation_fee'];
    final rawCompleted = r.getStringValue('completed_at');
    return Consultation(
      id: r.id,
      patientId: r.getStringValue('patient'),
      doctorId: r.getStringValue('doctor'),
      doctorName: doctorRecord?.getStringValue('name'),
      reasonForVisit: r.getStringValue('reason_for_visit'),
      notes: r.getStringValue('notes'),
      imageFilenames: r.getListValue<String>('images'),
      recommendation: ConsultationRecommendationX.fromRaw(r.getStringValue('recommendation')),
      consultationFee: rawFee == null ? null : (rawFee as num).toDouble(),
      suggestedProduct: r.getStringValue('suggested_product'),
      treatmentId: r.getStringValue('treatment'),
      status: r.getStringValue('status'),
      completedAt: rawCompleted.isEmpty ? null : DateTime.tryParse(rawCompleted),
      created: DateTime.tryParse(r.getStringValue('created')) ?? DateTime.now(),
    );
  }
}
