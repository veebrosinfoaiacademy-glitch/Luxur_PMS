import 'package:pocketbase/pocketbase.dart';

/// The clinic's treatment categories — the same four values used by
/// `treatments.treatment_type` and `treatment_plans.category`.
class TreatmentCategory {
  TreatmentCategory._();
  static const hair = 'Hair';
  static const skin = 'Skin';
  static const laser = 'Laser';
  static const bodyAesthetics = 'Body Aesthetics';

  static const all = [hair, skin, laser, bodyAesthetics];
}

/// Mirrors `treatment_plans`
/// (pocketbase/pb_migrations/1700000012_create_treatment_plans.js) — the
/// plans Admin configures in Settings, which the Doctor then picks from
/// when recommending a treatment.
///
/// A treatment snapshots the chosen plan's [name] into its own
/// `package_name`, so deactivating a plan hides it from NEW selections
/// without touching any patient's history.
class TreatmentPlan {
  final String id;
  final String category;
  final String name;
  final bool active;
  final DateTime created;

  const TreatmentPlan({
    required this.id,
    required this.category,
    required this.name,
    required this.active,
    required this.created,
  });

  factory TreatmentPlan.fromRecord(RecordModel r) {
    return TreatmentPlan(
      id: r.id,
      category: r.getStringValue('category'),
      name: r.getStringValue('name'),
      active: r.getBoolValue('active'),
      created: DateTime.tryParse(r.getStringValue('created')) ?? DateTime.now(),
    );
  }
}
