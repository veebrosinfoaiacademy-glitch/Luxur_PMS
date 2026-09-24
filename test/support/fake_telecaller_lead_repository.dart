import 'package:pms_vbis/features/telecaller/models/telecaller_lead.dart';
import 'package:pms_vbis/features/telecaller/repositories/telecaller_lead_repository.dart';
import 'package:pocketbase/pocketbase.dart';

/// An in-memory stand-in for [TelecallerLeadRepository] so widget tests can
/// drive the Telecaller screens with real view-model behaviour but no
/// network (a `testWidgets` binding fakes every HTTP call as a 400, so the
/// real repository can't be used there). Records what would have been
/// written so tests can assert "nothing was saved yet".
class FakeTelecallerLeadRepository extends TelecallerLeadRepository {
  FakeTelecallerLeadRepository({
    List<TelecallerLead> leads = const [],
    this.existingPhones = const {},
  })  : _leads = [...leads],
        super(PocketBase('http://127.0.0.1:8090'));

  final List<TelecallerLead> _leads;

  /// Phones the fake pretends are already in the database.
  final Set<String> existingPhones;

  int createCalls = 0;
  final List<String> createdPhones = [];
  final List<DateTime?> createdExpectedArrivals = [];

  @override
  Future<List<TelecallerLead>> listMine() async => List.of(_leads);

  @override
  Future<Set<String>> findExistingPhones(Set<String> normalizedPhones) async =>
      normalizedPhones.intersection(existingPhones);

  @override
  Future<TelecallerLead> create({
    required String name,
    required String normalizedPhone,
    String address = '',
    String concern = '',
    DateTime? expectedArrivalDate,
  }) async {
    createCalls++;
    createdPhones.add(normalizedPhone);
    createdExpectedArrivals.add(expectedArrivalDate);
    final lead = TelecallerLead(
      id: 'fake-$createCalls',
      name: name,
      phone: normalizedPhone,
      address: address,
      concern: concern,
      telecallerId: 'fake-telecaller',
      converted: false,
      created: DateTime.now(),
      expectedArrivalDate: expectedArrivalDate,
    );
    _leads.insert(0, lead);
    return lead;
  }
}
