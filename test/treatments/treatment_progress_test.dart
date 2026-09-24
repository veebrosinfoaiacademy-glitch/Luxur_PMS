import 'package:flutter_test/flutter_test.dart';
import 'package:pms_vbis/features/billing/models/bill.dart';
import 'package:pms_vbis/features/treatments/models/treatment.dart';
import 'package:pms_vbis/features/treatments/utils/treatment_progress.dart';

/// The worked examples in the Admin workflow spec, kept as executable
/// rules: progress counts PAID session fees only — never products, never
/// consultation fees — uses the amount actually marked paid, and is not
/// capped at 100%.
void main() {
  Treatment package(double cost, {String id = 't1'}) => Treatment(
        id: id,
        patientId: 'p1',
        category: 'Laser',
        packageName: 'Laser Hair Reduction',
        packageCost: cost,
        status: 'Active',
        consultationId: 'c1',
        created: DateTime(2026, 9, 1),
      );

  Bill bill({
    String treatmentId = 't1',
    String sessionId = 's1',
    String consultationId = '',
    double sessionFee = 0,
    double consultationFee = 0,
    double productCost = 0,
    bool paid = true,
  }) =>
      Bill(
        id: 'b${sessionId}_$consultationId',
        patientId: 'p1',
        consultationId: consultationId,
        sessionId: sessionId,
        treatmentId: treatmentId,
        billNumber: 'BILL-1',
        consultationCharge: consultationFee,
        treatmentFee: sessionFee,
        productName: productCost > 0 ? 'Serum' : '',
        productCost: productCost,
        totalAmount: sessionFee + consultationFee + productCost,
        paymentMethod: PaymentMethod.cash,
        paymentStatus: paid ? 'Paid' : 'Pending',
        paidAt: paid ? DateTime(2026, 9, 2) : null,
        created: DateTime(2026, 9, 2),
      );

  test('₹10,000 paid of a ₹50,000 package is 20%', () {
    final progress = treatmentProgressFrom(
      package(50000),
      [bill(sessionId: 's1', sessionFee: 10000)],
    );

    expect(progress.paidAmount, 10000);
    expect(progress.percent, 20);
    expect(progress.fraction, closeTo(0.2, 0.0001));
  });

  test('a partial payment counts the amount actually marked paid, not the amount first billed', () {
    // Billed ₹10,000, but the patient paid ₹5,000 — Admin edits the session
    // fee down to ₹5,000 before marking it paid.
    final progress = treatmentProgressFrom(
      package(50000),
      [bill(sessionId: 's1', sessionFee: 5000)],
    );

    expect(progress.paidAmount, 5000);
    expect(progress.percent, 10);
  });

  test('product amounts never count toward progress', () {
    final progress = treatmentProgressFrom(
      package(50000),
      [bill(sessionId: 's1', sessionFee: 10000, productCost: 2000)],
    );

    // ₹10,000 / ₹50,000 = 20%, NOT ₹12,000 / ₹50,000.
    expect(progress.paidAmount, 10000);
    expect(progress.percent, 20);
  });

  test('consultation fees never count toward progress', () {
    final progress = treatmentProgressFrom(
      package(50000),
      [
        // A paid consultation bill — no session attached.
        bill(sessionId: '', consultationId: 'c1', consultationFee: 1500),
        bill(sessionId: 's1', sessionFee: 10000),
      ],
    );

    expect(progress.paidAmount, 10000);
    expect(progress.percent, 20);
  });

  test('an unpaid session bill contributes nothing until Patient Paid', () {
    final generatedOnly = treatmentProgressFrom(
      package(50000),
      [bill(sessionId: 's1', sessionFee: 10000, paid: false)],
    );
    expect(generatedOnly.paidAmount, 0);
    expect(generatedOnly.percent, 0);

    final afterPaid = treatmentProgressFrom(
      package(50000),
      [bill(sessionId: 's1', sessionFee: 10000, paid: true)],
    );
    expect(afterPaid.percent, 20);
  });

  test('progress is not capped at 100%', () {
    final progress = treatmentProgressFrom(
      package(50000),
      [
        bill(sessionId: 's1', sessionFee: 30000),
        bill(sessionId: 's2', sessionFee: 30000),
      ],
    );

    expect(progress.paidAmount, 60000);
    expect(progress.percent, 120);
  });

  test('paid sessions accumulate across the treatment', () {
    final progress = treatmentProgressFrom(
      package(50000),
      [
        bill(sessionId: 's1', sessionFee: 10000),
        bill(sessionId: 's2', sessionFee: 5000),
        bill(sessionId: 's3', sessionFee: 10000, paid: false),
      ],
    );

    expect(progress.paidAmount, 15000);
    expect(progress.percent, 30);
    expect(progress.remaining, 35000);
  });

  test('another treatment\'s paid sessions do not leak into this one', () {
    final progress = treatmentProgressFrom(
      package(50000, id: 't1'),
      [
        bill(treatmentId: 't1', sessionId: 's1', sessionFee: 10000),
        bill(treatmentId: 't2', sessionId: 's9', sessionFee: 40000),
      ],
    );

    expect(progress.paidAmount, 10000);
    expect(progress.percent, 20);
  });

  test('a package with no cost reads as 0% instead of dividing by zero', () {
    final progress = treatmentProgressFrom(
      package(0),
      [bill(sessionId: 's1', sessionFee: 10000)],
    );

    expect(progress.fraction, 0);
    expect(progress.percent, 0);
  });
}
