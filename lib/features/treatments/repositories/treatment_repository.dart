import 'package:pocketbase/pocketbase.dart';

import '../models/treatment.dart';

/// A patient's treatment packages. Created by the Doctor when a
/// consultation recommends treatment — never at registration.
class TreatmentRepository {
  TreatmentRepository(this._pb);

  final PocketBase _pb;

  RecordService get _collection => _pb.collection('treatments');

  String get _authenticatedUserId {
    final id = _pb.authStore.record?.id;
    if (id == null) {
      throw StateError('No authenticated user — cannot create a treatment.');
    }
    return id;
  }

  Future<List<Treatment>> listForPatient(String patientId) async {
    final records = await _collection.getFullList(
      filter: 'patient = "$patientId"',
      sort: '-created',
    );
    return records.map(Treatment.fromRecord).toList();
  }

  /// [packageName] is a snapshot of the chosen plan's name, and
  /// [sessionsTotal] is optional — a treatment need not declare a count.
  Future<Treatment> create({
    required String patientId,
    required String category,
    required String packageName,
    required double packageCost,
    int? sessionsTotal,
    String? consultationId,
  }) async {
    final record = await _collection.create(body: {
      'patient': patientId,
      'treatment_type': category,
      'package_name': packageName,
      'package_cost': packageCost,
      if (sessionsTotal != null) 'sessions_total': sessionsTotal,
      if (sessionsTotal != null) 'sessions_remaining': sessionsTotal,
      if (consultationId != null) 'consultation': consultationId,
      'status': 'Active',
      'created_by': _authenticatedUserId,
    });
    return Treatment.fromRecord(record);
  }
}
