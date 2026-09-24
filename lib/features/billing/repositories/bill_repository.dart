import 'package:pocketbase/pocketbase.dart';

import '../models/bill.dart';

/// Consultation bills and session bills — two separate flows that happen to
/// share a table. A bill is generated UNPAID; only [markPaid] (Admin's
/// "Patient Paid") settles it, and the server stamps when that happened.
class BillRepository {
  BillRepository(this._pb);

  final PocketBase _pb;

  RecordService get _collection => _pb.collection('bills');

  String get _authenticatedUserId {
    final id = _pb.authStore.record?.id;
    if (id == null) {
      throw StateError('No authenticated user — cannot create a bill.');
    }
    return id;
  }

  Future<List<Bill>> listForPatient(String patientId) async {
    final records = await _collection.getFullList(
      filter: 'patient = "$patientId"',
      sort: '-created',
    );
    return records.map(Bill.fromRecord).toList();
  }

  Future<Bill?> findForConsultation(String consultationId) async {
    final results = await _collection.getList(
      page: 1,
      perPage: 1,
      filter: 'consultation = "$consultationId"',
      sort: '-created',
    );
    if (results.items.isEmpty) return null;
    return Bill.fromRecord(results.items.first);
  }

  Future<Bill?> findForSession(String sessionId) async {
    final results = await _collection.getList(
      page: 1,
      perPage: 1,
      filter: 'session = "$sessionId"',
      sort: '-created',
    );
    if (results.items.isEmpty) return null;
    return Bill.fromRecord(results.items.first);
  }

  Future<String> _nextBillNumber(int attempt) async {
    final countResult = await _collection.getList(page: 1, perPage: 1);
    final sequence = countResult.totalItems + 1 + attempt;
    return 'BILL-${DateTime.now().year}-${sequence.toString().padLeft(4, '0')}';
  }

  Future<RecordModel> _createWithBillNumber(Map<String, dynamic> body) async {
    ClientException? lastError;
    for (var attempt = 0; attempt < 5; attempt++) {
      try {
        return await _collection.create(body: {
          ...body,
          'bill_number': await _nextBillNumber(attempt),
        });
      } on ClientException catch (e) {
        final data = e.response['data'];
        final isBillNumberConflict = data is Map && data.containsKey('bill_number');
        if (!isBillNumberConflict) rethrow;
        lastError = e;
      }
    }
    throw lastError ?? StateError('Could not generate a unique bill number.');
  }

  /// Generating a consultation bill does NOT take payment.
  Future<Bill> createConsultationBill({
    required String patientId,
    required String consultationId,
    required double consultationFee,
    String productName = '',
    double productCost = 0,
    required String paymentMethod,
  }) async {
    final record = await _createWithBillNumber({
      'patient': patientId,
      'consultation': consultationId,
      'consultation_charge': consultationFee,
      'product_name': productName,
      'product_cost': productCost,
      'total_amount': consultationFee + productCost,
      'payment_method': paymentMethod,
      'payment_status': 'Pending',
      'created_by': _authenticatedUserId,
    });
    return Bill.fromRecord(record);
  }

  /// Generating a session bill does NOT take payment, and does not move the
  /// treatment progress bar until it is marked paid.
  Future<Bill> createSessionBill({
    required String patientId,
    required String sessionId,
    required String treatmentId,
    required double sessionFee,
    String productName = '',
    double productCost = 0,
    required String paymentMethod,
  }) async {
    final record = await _createWithBillNumber({
      'patient': patientId,
      'session': sessionId,
      'treatment': treatmentId,
      'treatment_fee': sessionFee,
      'product_name': productName,
      'product_cost': productCost,
      'total_amount': sessionFee + productCost,
      'payment_method': paymentMethod,
      'payment_status': 'Pending',
      'created_by': _authenticatedUserId,
    });
    return Bill.fromRecord(record);
  }

  /// Amends an unpaid bill — this is how a partial payment is recorded:
  /// Admin edits the fee down to what the patient actually pays, then marks
  /// it paid.
  Future<Bill> updateAmounts(
    String id, {
    double? consultationFee,
    double? sessionFee,
    String? productName,
    double? productCost,
    String? paymentMethod,
  }) async {
    final current = Bill.fromRecord(await _collection.getOne(id));
    final newConsultation = consultationFee ?? current.consultationCharge;
    final newSession = sessionFee ?? current.treatmentFee;
    final newProductCost = productCost ?? current.productCost;

    final record = await _collection.update(id, body: {
      'consultation_charge': newConsultation,
      'treatment_fee': newSession,
      if (productName != null) 'product_name': productName,
      'product_cost': newProductCost,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      'total_amount': newConsultation + newSession + newProductCost,
    });
    return Bill.fromRecord(record);
  }

  /// "Patient Paid". `paid_at` is stamped server-side
  /// (pb_hooks/bills_payment.pb.js).
  Future<Bill> markPaid(String id) async {
    final record = await _collection.update(id, body: {'payment_status': 'Paid'});
    return Bill.fromRecord(record);
  }
}
