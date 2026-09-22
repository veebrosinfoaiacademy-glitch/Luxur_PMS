import 'package:pocketbase/pocketbase.dart';

/// Mirrors the `telecaller_leads` PocketBase collection
/// (pocketbase/pb_migrations/1700000003_create_telecaller_leads.js +
/// 1700000005_add_converted_patient_to_leads.js). Separate from the main
/// clinic `patients` collection by design — see the pms-project skill.
class TelecallerLead {
  final String id;
  final String name;
  final String phone;
  final String address;
  final String concern;
  final String telecallerId;
  final bool converted;
  final DateTime created;

  const TelecallerLead({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.concern,
    required this.telecallerId,
    required this.converted,
    required this.created,
  });

  factory TelecallerLead.fromRecord(RecordModel r) {
    return TelecallerLead(
      id: r.id,
      name: r.getStringValue('name'),
      phone: r.getStringValue('phone'),
      address: r.getStringValue('address'),
      concern: r.getStringValue('concern'),
      telecallerId: r.getStringValue('telecaller'),
      converted: r.getBoolValue('converted'),
      created: DateTime.tryParse(r.getStringValue('created')) ?? DateTime.now(),
    );
  }
}
