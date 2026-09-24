import '../../billing/models/bill.dart';
import '../models/treatment.dart';

/// How far a patient has paid through a treatment package.
///
/// The rules here are deliberately narrow, because money is involved:
///
///  * ONLY session fees that have actually been marked "Patient Paid"
///    count. Generating a bill changes nothing.
///  * Product amounts NEVER count, even on a paid session bill.
///  * Consultation fees NEVER count — consultation billing is a separate
///    flow from treatment billing.
///  * The amount that counts is whatever was billed as the session fee at
///    the time it was paid, so an Admin who edits a ₹10,000 fee down to
///    ₹5,000 before marking it paid contributes exactly ₹5,000.
///  * Progress is NOT capped at 100% — paying more than the package cost
///    legitimately shows as over 100%.
class TreatmentProgress {
  /// Total of the session fees paid so far.
  final double paidAmount;
  /// The package cost this is measured against.
  final double packageCost;

  const TreatmentProgress({required this.paidAmount, required this.packageCost});

  /// 0.2 for ₹10,000 paid of a ₹50,000 package. Can exceed 1.0.
  /// Zero when the package has no cost, so the UI never divides by zero.
  double get fraction => packageCost <= 0 ? 0 : paidAmount / packageCost;

  /// 20 for the example above. Rounded for display only.
  int get percent => (fraction * 100).round();

  double get remaining => packageCost - paidAmount;
}

/// Computes [TreatmentProgress] for [treatment] from [bills].
///
/// [bills] may contain every bill for the patient — consultation bills,
/// other treatments' session bills and unpaid bills are all filtered out
/// here rather than by the caller.
TreatmentProgress treatmentProgressFrom(Treatment treatment, List<Bill> bills) {
  var paid = 0.0;
  for (final bill in bills) {
    if (!bill.isPaid) continue;
    if (!bill.isSessionBill) continue; // excludes consultation bills
    if (bill.treatmentId != treatment.id) continue;
    paid += bill.treatmentFee; // excludes productCost by construction
  }
  return TreatmentProgress(paidAmount: paid, packageCost: treatment.packageCost);
}
