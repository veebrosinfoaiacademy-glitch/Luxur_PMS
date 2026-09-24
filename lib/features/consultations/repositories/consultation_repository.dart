import 'package:http/http.dart' as http;
import 'package:pocketbase/pocketbase.dart';

import '../models/consultation.dart';

/// Consultations, including their images.
///
/// Doctor attribution and the completion timestamp are both set
/// server-side (pb_hooks/consultations_workflow.pb.js) rather than trusted
/// from here.
class ConsultationRepository {
  ConsultationRepository(this._pb);

  final PocketBase _pb;

  RecordService get _collection => _pb.collection('consultations');

  String get _authenticatedUserId {
    final id = _pb.authStore.record?.id;
    if (id == null) {
      throw StateError('No authenticated user — cannot record a consultation.');
    }
    return id;
  }

  Future<List<Consultation>> listForPatient(String patientId) async {
    final records = await _collection.getFullList(
      filter: 'patient = "$patientId"',
      sort: '-created',
      expand: 'doctor',
    );
    return records.map(Consultation.fromRecord).toList();
  }

  Future<Consultation?> getById(String id) async {
    try {
      return Consultation.fromRecord(await _collection.getOne(id, expand: 'doctor'));
    } catch (_) {
      return null;
    }
  }

  /// Patients who still need a consultation today — the Doctor's
  /// "Waiting for Consultation" queue is built from this plus today's
  /// patients.
  Future<Set<String>> patientIdsWithCompletedConsultation(List<String> patientIds) async {
    if (patientIds.isEmpty) return {};
    final clause = patientIds.map((id) => 'patient = "$id"').join(' || ');
    final records = await _collection.getFullList(
      filter: 'status = "completed" && ($clause)',
    );
    return records.map((r) => r.getStringValue('patient')).toSet();
  }

  /// The one place that turns a stored filename into a URL — keeps a later
  /// move to external object storage a single-method change.
  Uri imageUrl(Consultation consultation, String filename) {
    return _pb.files.getURL(
      RecordModel.fromJson({
        'id': consultation.id,
        'collectionId': 'consultations',
        'collectionName': 'consultations',
      }),
      filename,
    );
  }

  /// Saves a consultation as a draft ("Save Notes").
  Future<Consultation> saveDraft({
    required String patientId,
    String reasonForVisit = '',
    String notes = '',
  }) async {
    final record = await _collection.create(body: {
      'patient': patientId,
      'reason_for_visit': reasonForVisit,
      'notes': notes,
      'status': 'draft',
      'created_by': _authenticatedUserId,
    });
    return Consultation.fromRecord(record);
  }

  Future<Consultation> updateDraft(
    String id, {
    String? reasonForVisit,
    String? notes,
  }) async {
    final record = await _collection.update(id, body: {
      if (reasonForVisit != null) 'reason_for_visit': reasonForVisit,
      if (notes != null) 'notes': notes,
    });
    return Consultation.fromRecord(record);
  }

  Future<Consultation> uploadImages(String id, List<(String filename, List<int> bytes)> files) async {
    final record = await _collection.update(
      id,
      files: [
        for (final (filename, bytes) in files)
          http.MultipartFile.fromBytes('images', bytes, filename: filename),
      ],
    );
    return Consultation.fromRecord(record);
  }

  /// "Complete Consultation". [consultationFee] is optional on both the
  /// treatment and no-treatment paths. [treatmentId] is set only when a
  /// treatment was recommended and created.
  Future<Consultation> complete(
    String id, {
    required ConsultationRecommendation recommendation,
    String reasonForVisit = '',
    String notes = '',
    double? consultationFee,
    String suggestedProduct = '',
    String? treatmentId,
  }) async {
    final record = await _collection.update(id, body: {
      'reason_for_visit': reasonForVisit,
      'notes': notes,
      'recommendation': recommendation.raw,
      'consultation_fee': consultationFee,
      'suggested_product': suggestedProduct,
      if (treatmentId != null) 'treatment': treatmentId,
      'status': 'completed',
    });
    return Consultation.fromRecord(record);
  }
}
