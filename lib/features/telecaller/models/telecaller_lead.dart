import 'package:pocketbase/pocketbase.dart';

/// Mirrors the `telecaller_leads` PocketBase collection
/// (pocketbase/pb_migrations/1700000003_create_telecaller_leads.js +
/// 1700000005_add_converted_patient_to_leads.js +
/// 1700000011_add_expected_arrival_to_leads.js). Separate from the main
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
  /// Date-only (no time-of-day). Null for leads created before this field
  /// existed, or created via bulk import with the column left blank — such
  /// leads are simply excluded from Follow-Up until a date is known.
  final DateTime? expectedArrivalDate;
  /// Only populated when the record was fetched with `expand: 'telecaller'`
  /// — i.e. Admin's lead lookup during patient registration, which has to
  /// show "added by" attribution. Null on every Telecaller-scoped read.
  final String? telecallerName;

  const TelecallerLead({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.concern,
    required this.telecallerId,
    required this.converted,
    required this.created,
    this.expectedArrivalDate,
    this.telecallerName,
  });

  factory TelecallerLead.fromRecord(RecordModel r) {
    final rawExpectedArrival = r.getStringValue('expected_arrival_date');
    final telecallerRecord = r.get<RecordModel?>('expand.telecaller', null);
    return TelecallerLead(
      id: r.id,
      name: r.getStringValue('name'),
      phone: r.getStringValue('phone'),
      address: r.getStringValue('address'),
      concern: r.getStringValue('concern'),
      telecallerId: r.getStringValue('telecaller'),
      converted: r.getBoolValue('converted'),
      created: DateTime.tryParse(r.getStringValue('created')) ?? DateTime.now(),
      expectedArrivalDate: rawExpectedArrival.isEmpty
          ? null
          : DateTime.tryParse(rawExpectedArrival),
      telecallerName: telecallerRecord?.getStringValue('name'),
    );
  }
}
