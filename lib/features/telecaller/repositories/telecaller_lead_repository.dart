import 'package:pocketbase/pocketbase.dart';
import '../models/telecaller_lead.dart';

class DuplicateLeadException implements Exception {
  final String phone;
  DuplicateLeadException(this.phone);
}

/// All reads/writes go through the authenticated `users` session — the
/// PocketBase `telecaller_leads` API rules (not this class) are what
/// actually stop a Telecaller reading/writing another Telecaller's leads.
/// This class exists to (a) keep that query logic in one place and
/// (b) guarantee attribution is always the *authenticated* caller, never a
/// value the UI or an imported file could hand it.
class TelecallerLeadRepository {
  TelecallerLeadRepository(this._pb);

  final PocketBase _pb;

  RecordService get _collection => _pb.collection('telecaller_leads');

  String get _authenticatedTelecallerId {
    final id = _pb.authStore.record?.id;
    if (id == null) {
      throw StateError('No authenticated user — cannot attribute a lead.');
    }
    return id;
  }

  /// Leads visible to the caller (server-side rules already scope this to
  /// "my own leads" for a telecaller), newest first.
  Future<List<TelecallerLead>> listMine() async {
    final records = await _collection.getFullList(sort: '-created');
    return records.map(TelecallerLead.fromRecord).toList();
  }

  /// True if the authenticated telecaller already has a lead with this
  /// (already-normalized) phone number.
  Future<bool> existsWithPhone(String normalizedPhone) async {
    final results = await _collection.getList(
      page: 1,
      perPage: 1,
      filter: 'phone = "$normalizedPhone"',
    );
    return results.totalItems > 0;
  }

  /// Given a batch of normalized phone numbers (e.g. from an Excel import),
  /// returns the subset that already exist among the authenticated
  /// telecaller's leads. One query instead of one-per-row.
  Future<Set<String>> findExistingPhones(Set<String> normalizedPhones) async {
    if (normalizedPhones.isEmpty) return {};
    final mine = await listMine();
    final mineSet = mine.map((l) => l.phone).toSet();
    return normalizedPhones.intersection(mineSet);
  }

  /// Creates one lead attributed to the authenticated telecaller. Throws
  /// [DuplicateLeadException] if that telecaller already has this phone
  /// number on file — callers should normally check [existsWithPhone]
  /// first, but this guards against races (e.g. two tabs, or a batch
  /// import creating the same number twice).
  Future<TelecallerLead> create({
    required String name,
    required String normalizedPhone,
    String address = '',
    String concern = '',
  }) async {
    if (await existsWithPhone(normalizedPhone)) {
      throw DuplicateLeadException(normalizedPhone);
    }

    final record = await _collection.create(body: {
      'name': name,
      'phone': normalizedPhone,
      'address': address,
      'concern': concern,
      'telecaller': _authenticatedTelecallerId,
      'converted': false,
    });
    return TelecallerLead.fromRecord(record);
  }
}
