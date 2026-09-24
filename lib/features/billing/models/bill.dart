import 'package:pocketbase/pocketbase.dart';

/// Matches the `bills.payment_method` select.
class PaymentMethod {
  PaymentMethod._();
  static const cash = 'Cash';
  static const online = 'Online';
  static const all = [cash, online];
}

/// Mirrors `bills` (pocketbase/pb_migrations/1700000009_create_billing.js +
/// 1700000015_extend_treatments_and_bills.js).
///
/// A bill is either a CONSULTATION bill or a SESSION bill — never both.
/// The two flows are deliberately separate, and only session bills can
/// move the treatment progress bar (and then only by their fee, never
/// their product amount).
///
/// Generating a bill does not make it paid: [isPaid] only becomes true when
/// Admin explicitly marks "Patient Paid", at which point the server stamps
/// [paidAt].
class Bill {
  final String id;
  final String patientId;
  final String consultationId;
  final String sessionId;
  final String treatmentId;
  final String billNumber;
  /// The consultation fee on a consultation bill.
  final double consultationCharge;
  /// The session fee on a session bill — the amount that counts toward
  /// treatment progress once paid. Admin may edit it down before marking
  /// paid, which is how partial payment is recorded.
  final double treatmentFee;
  final String productName;
  /// Never counts toward treatment progress.
  final double productCost;
  final double totalAmount;
  final String paymentMethod;
  final String paymentStatus;
  final DateTime? paidAt;
  final DateTime created;

  const Bill({
    required this.id,
    required this.patientId,
    required this.consultationId,
    required this.sessionId,
    required this.treatmentId,
    required this.billNumber,
    required this.consultationCharge,
    required this.treatmentFee,
    required this.productName,
    required this.productCost,
    required this.totalAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    this.paidAt,
    required this.created,
  });

  bool get isPaid => paymentStatus == 'Paid';
  bool get isSessionBill => sessionId.isNotEmpty;
  bool get isConsultationBill => consultationId.isNotEmpty;

  factory Bill.fromRecord(RecordModel r) {
    double number(String field) {
      final value = r.data[field];
      return value == null ? 0 : (value as num).toDouble();
    }

    final rawPaidAt = r.getStringValue('paid_at');
    return Bill(
      id: r.id,
      patientId: r.getStringValue('patient'),
      consultationId: r.getStringValue('consultation'),
      sessionId: r.getStringValue('session'),
      treatmentId: r.getStringValue('treatment'),
      billNumber: r.getStringValue('bill_number'),
      consultationCharge: number('consultation_charge'),
      treatmentFee: number('treatment_fee'),
      productName: r.getStringValue('product_name'),
      productCost: number('product_cost'),
      totalAmount: number('total_amount'),
      paymentMethod: r.getStringValue('payment_method'),
      paymentStatus: r.getStringValue('payment_status'),
      paidAt: rawPaidAt.isEmpty ? null : DateTime.tryParse(rawPaidAt),
      created: DateTime.tryParse(r.getStringValue('created')) ?? DateTime.now(),
    );
  }
}
