import 'package:pocketbase/pocketbase.dart';

/// Mirrors `treatments` (pocketbase/pb_migrations/1700000006_create_treatments.js
/// plus 1700000015_extend_treatments_and_bills.js).
///
/// A patient may have several treatments. [packageCost] is the baseline the
/// progress bar measures PAID session fees against — see
/// TreatmentProgress.
class Treatment {
  final String id;
  final String patientId;
  final String category;
  /// Snapshot of the chosen TreatmentPlan's name at the time it was
  /// selected, so it stays correct even if that plan is later deactivated.
  final String packageName;
  final double packageCost;
  /// Optional — a treatment does not have to declare a session count.
  final int? sessionsTotal;
  final String status;
  final String consultationId;
  final DateTime created;

  const Treatment({
    required this.id,
    required this.patientId,
    required this.category,
    required this.packageName,
    required this.packageCost,
    this.sessionsTotal,
    required this.status,
    required this.consultationId,
    required this.created,
  });

  bool get isActive => status == 'Active';

  factory Treatment.fromRecord(RecordModel r) {
    // An empty number field comes back as 0, not null, so a treatment that
    // never declared a session count is indistinguishable from one set to
    // zero — and zero sessions is not a package anyone can sell. Both mean
    // "no count declared".
    final rawTotal = r.data['sessions_total'];
    final total = rawTotal == null ? 0 : (rawTotal as num).toInt();
    final rawCost = r.data['package_cost'];
    return Treatment(
      id: r.id,
      patientId: r.getStringValue('patient'),
      category: r.getStringValue('treatment_type'),
      packageName: r.getStringValue('package_name'),
      packageCost: rawCost == null ? 0 : (rawCost as num).toDouble(),
      sessionsTotal: total <= 0 ? null : total,
      status: r.getStringValue('status'),
      consultationId: r.getStringValue('consultation'),
      created: DateTime.tryParse(r.getStringValue('created')) ?? DateTime.now(),
    );
  }
}
