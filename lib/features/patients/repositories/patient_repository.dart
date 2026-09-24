import 'package:pocketbase/pocketbase.dart';

import '../../telecaller/models/telecaller_lead.dart';
import '../../telecaller/repositories/telecaller_lead_repository.dart';
import '../models/patient.dart';

class DuplicatePatientException implements Exception {
  final String phone;
  final Patient existing;
  DuplicatePatientException(this.phone, this.existing);
}

/// The main patient database. A Telecaller lead only crosses into it here,
/// via [create]'s `telecallerLeadId` — and when it does, the Telecaller
/// attribution is written onto the patient permanently.
class PatientRepository {
  PatientRepository(this._pb, this._telecallerLeadRepository);

  final PocketBase _pb;
  final TelecallerLeadRepository _telecallerLeadRepository;

  RecordService get _collection => _pb.collection('patients');

  String get _authenticatedUserId {
    final id = _pb.authStore.record?.id;
    if (id == null) {
      throw StateError('No authenticated user — cannot attribute a patient record.');
    }
    return id;
  }

  Future<List<Patient>> listAll() async {
    final records = await _collection.getFullList(
      sort: '-created',
      filter: 'archived = false',
      expand: 'telecaller',
    );
    return records.map(Patient.fromRecord).toList();
  }

  Future<Patient?> getById(String id) async {
    try {
      return Patient.fromRecord(await _collection.getOne(id, expand: 'telecaller'));
    } catch (_) {
      return null;
    }
  }

  /// Patients registered today — the base of the Admin's Today's Schedule.
  Future<List<Patient>> listRegisteredToday({DateTime? now}) async {
    final today = now ?? DateTime.now();
    final start = DateTime.utc(today.year, today.month, today.day).toIso8601String();
    final end = DateTime.utc(today.year, today.month, today.day)
        .add(const Duration(days: 1))
        .toIso8601String();
    final records = await _collection.getFullList(
      filter: 'archived = false && created >= "$start" && created < "$end"',
      sort: '-created',
      expand: 'telecaller',
    );
    return records.map(Patient.fromRecord).toList();
  }

  /// Headline counts for the dashboard. Asks the server for totals rather
  /// than downloading every patient to count them.
  Future<({int total, int joined})> counts() async {
    final all = await _collection.getList(
      page: 1,
      perPage: 1,
      filter: 'archived = false',
    );
    final joined = await _collection.getList(
      page: 1,
      perPage: 1,
      filter: 'archived = false && status = "Joined"',
    );
    return (total: all.totalItems, joined: joined.totalItems);
  }

  /// Front-desk search by mobile number or patient ID — filtered on the
  /// server rather than by loading the whole table.
  Future<List<Patient>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];
    final escaped = q.replaceAll('"', r'\"');
    final records = await _collection.getFullList(
      sort: '-created',
      filter: 'archived = false && (phone ~ "$escaped" || patient_code ~ "$escaped")',
      expand: 'telecaller',
    );
    return records.map(Patient.fromRecord).toList();
  }

  Future<Patient?> findByPhone(String normalizedPhone) async {
    final results = await _collection.getList(
      page: 1,
      perPage: 1,
      filter: 'phone = "$normalizedPhone"',
      expand: 'telecaller',
    );
    if (results.items.isEmpty) return null;
    return Patient.fromRecord(results.items.first);
  }

  /// Does an un-converted Telecaller lead exist for this number? Drives the
  /// auto-fill step of registration.
  Future<TelecallerLead?> findMatchingTelecallerLead(String normalizedPhone) {
    return _telecallerLeadRepository.findByPhoneAsAdmin(normalizedPhone);
  }

  Future<String> _nextPatientCode(int attempt) async {
    final countResult = await _collection.getList(page: 1, perPage: 1);
    return 'PT-${1000 + countResult.totalItems + 1 + attempt}';
  }

  static bool _isUniqueCodeConflict(ClientException e) {
    final data = e.response['data'];
    return data is Map && data.containsKey('patient_code');
  }

  /// Registers a patient. Note there is no doctor parameter — doctors are
  /// never assigned at registration.
  ///
  /// Throws [DuplicatePatientException] if the number already belongs to a
  /// patient, so the caller can show that patient instead of creating a
  /// second one.
  Future<Patient> create({
    required String name,
    required String normalizedPhone,
    required String source,
    int? age,
    String gender = '',
    String address = '',
    String referralName = '',
    String concern = '',
    String? telecallerLeadId,
    String? telecallerId,
  }) async {
    final existing = await findByPhone(normalizedPhone);
    if (existing != null) {
      throw DuplicatePatientException(normalizedPhone, existing);
    }

    RecordModel? record;
    ClientException? lastError;
    for (var attempt = 0; attempt < 5 && record == null; attempt++) {
      try {
        record = await _collection.create(body: {
          'patient_code': await _nextPatientCode(attempt),
          'name': name,
          if (age != null) 'age': age,
          'gender': gender,
          'phone': normalizedPhone,
          'address': address,
          'source': source,
          'referral_name': referralName,
          'concern': concern,
          if (telecallerLeadId != null) 'telecaller_lead': telecallerLeadId,
          if (telecallerId != null) 'telecaller': telecallerId,
          'status': 'Joined',
          'archived': false,
          'created_by': _authenticatedUserId,
        });
      } on ClientException catch (e) {
        if (!_isUniqueCodeConflict(e)) rethrow;
        lastError = e;
      }
    }
    if (record == null) {
      throw lastError ?? StateError('Could not generate a unique patient code.');
    }

    final patient = Patient.fromRecord(record);

    // Mark the originating lead converted and link it, without ever
    // clearing its Telecaller attribution.
    if (telecallerLeadId != null) {
      await _pb.collection('telecaller_leads').update(telecallerLeadId, body: {
        'converted': true,
        'converted_patient': patient.id,
      });
    }

    return patient;
  }

  /// Corrects a patient's own details. Only the fields collected at
  /// registration are editable — the patient code, the Telecaller
  /// attribution and every clinical record stay exactly as they are.
  ///
  /// Throws [DuplicatePatientException] if the new number already belongs to
  /// a different patient, so two records can't end up sharing a phone.
  Future<Patient> update(
    String id, {
    required String name,
    required String normalizedPhone,
    required String source,
    int? age,
    String gender = '',
    String address = '',
    String referralName = '',
    String concern = '',
  }) async {
    final existing = await findByPhone(normalizedPhone);
    if (existing != null && existing.id != id) {
      throw DuplicatePatientException(normalizedPhone, existing);
    }

    final record = await _collection.update(id, body: {
      'name': name,
      'age': age,
      'gender': gender,
      'phone': normalizedPhone,
      'address': address,
      'source': source,
      'referral_name': referralName,
      'concern': concern,
    }, expand: 'telecaller');
    return Patient.fromRecord(record);
  }

  /// Deleting a patient archives them: the record and its consultations,
  /// sessions and bills are kept, it simply stops appearing anywhere in the
  /// app. The collection has no delete rule at all, so nothing here — or in
  /// the UI — can destroy a patient's history.
  Future<Patient> archive(String id) async {
    final record = await _collection.update(
      id,
      body: {'archived': true},
      expand: 'telecaller',
    );
    return Patient.fromRecord(record);
  }
}
