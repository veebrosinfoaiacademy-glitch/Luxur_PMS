import 'package:pocketbase/pocketbase.dart';

import '../models/treatment_plan.dart';

/// The clinic's configurable treatment plans (Admin Settings).
///
/// Plans are activated/deactivated, never deleted: a deactivated plan
/// disappears from NEW treatment selection while every past treatment that
/// used it keeps its snapshotted name.
class TreatmentPlanRepository {
  TreatmentPlanRepository(this._pb);

  final PocketBase _pb;

  RecordService get _collection => _pb.collection('treatment_plans');

  String get _authenticatedUserId {
    final id = _pb.authStore.record?.id;
    if (id == null) {
      throw StateError('No authenticated user — cannot configure treatment plans.');
    }
    return id;
  }

  /// Every plan, active or not — for the Settings management screen.
  Future<List<TreatmentPlan>> listAll() async {
    final records = await _collection.getFullList(sort: 'category,name');
    return records.map(TreatmentPlan.fromRecord).toList();
  }

  /// Only what a Doctor may pick right now for [category].
  Future<List<TreatmentPlan>> listActiveForCategory(String category) async {
    final records = await _collection.getFullList(
      filter: 'category = "$category" && active = true',
      sort: 'name',
    );
    return records.map(TreatmentPlan.fromRecord).toList();
  }

  Future<TreatmentPlan> create({required String category, required String name}) async {
    final record = await _collection.create(body: {
      'category': category,
      'name': name.trim(),
      'active': true,
      'created_by': _authenticatedUserId,
    });
    return TreatmentPlan.fromRecord(record);
  }

  Future<TreatmentPlan> update(String id, {String? category, String? name}) async {
    final record = await _collection.update(id, body: {
      if (category != null) 'category': category,
      if (name != null) 'name': name.trim(),
    });
    return TreatmentPlan.fromRecord(record);
  }

  Future<TreatmentPlan> setActive(String id, bool active) async {
    final record = await _collection.update(id, body: {'active': active});
    return TreatmentPlan.fromRecord(record);
  }
}
