import 'package:pocketbase/pocketbase.dart';

/// A doctor who can be picked for a single session. Sourced from the real
/// `users` collection (role = "doctor"), never a hardcoded name list.
///
/// This is only ever used for OPTIONAL, per-session assignment — there is
/// no permanent patient -> doctor relationship anywhere in this app.
class DoctorOption {
  final String id;
  final String name;
  const DoctorOption({required this.id, required this.name});

  factory DoctorOption.fromRecord(RecordModel r) {
    final name = r.getStringValue('name');
    return DoctorOption(id: r.id, name: name.isEmpty ? r.getStringValue('email') : name);
  }
}

/// Shared by every repository that needs "the real active doctors", so the
/// query lives in one place.
Future<List<DoctorOption>> listActiveDoctors(PocketBase pb) async {
  final records = await pb.collection('users').getFullList(
        filter: 'role = "doctor" && active = true',
        sort: 'name',
      );
  return records.map(DoctorOption.fromRecord).toList();
}
