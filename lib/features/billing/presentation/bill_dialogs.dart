import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/state/clinic_view_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/bill.dart';

String _money(double amount) =>
    NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(amount);

/// "Patient Paid" — the settlement step, which is deliberately separate
/// from generating the bill.
///
/// Admin can correct the amount and the payment mode here before settling;
/// paying less than the billed amount is how a partial payment is recorded,
/// and it is the paid amount that moves the treatment progress.
class CollectPaymentDialog extends StatefulWidget {
  const CollectPaymentDialog({super.key, required this.clinic, required this.bill});

  final ClinicViewModel clinic;
  final Bill bill;

  static Future<void> show(BuildContext context, ClinicViewModel clinic, Bill bill) {
    return showDialog(
      context: context,
      builder: (context) => CollectPaymentDialog(clinic: clinic, bill: bill),
    );
  }

  @override
  State<CollectPaymentDialog> createState() => _CollectPaymentDialogState();
}

class _CollectPaymentDialogState extends State<CollectPaymentDialog> {
  late final _amountController = TextEditingController(
    text: _billedFee.toStringAsFixed(0),
  );
  late String _paymentMethod =
      widget.bill.paymentMethod.isEmpty ? PaymentMethod.cash : widget.bill.paymentMethod;

  bool _busy = false;
  String? _error;

  double get _billedFee =>
      widget.bill.isSessionBill ? widget.bill.treatmentFee : widget.bill.consultationCharge;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter the amount the patient paid.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      if (amount != _billedFee || _paymentMethod != widget.bill.paymentMethod) {
        await widget.clinic.bills.updateAmounts(
          widget.bill.id,
          consultationFee: widget.bill.isConsultationBill ? amount : null,
          sessionFee: widget.bill.isSessionBill ? amount : null,
          paymentMethod: _paymentMethod,
        );
      }
      await widget.clinic.markBillPaid(widget.bill.id);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Could not record the payment. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Record Payment',
        style: AppTypography.headingSmall.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.bill.billNumber} · billed ${_money(widget.bill.totalAmount)}',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5, color: const Color(0xFF6B7280)),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('payment_amount'),
              controller: _amountController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Amount paid',
                prefixText: '₹ ',
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Enter less than the billed amount to record a part payment.',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5, color: const Color(0xFF6B7280)),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _paymentMethod,
              decoration: const InputDecoration(labelText: 'Payment mode'),
              items: PaymentMethod.all
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _paymentMethod = v);
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5, color: const Color(0xFFDC2626)),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          key: const Key('confirm_patient_paid'),
          onPressed: _busy ? null : _confirm,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: _busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Patient Paid'),
        ),
      ],
    );
  }
}

/// A read-only look at a generated bill.
class BillPreviewDialog extends StatelessWidget {
  const BillPreviewDialog({super.key, required this.clinic, required this.bill});

  final ClinicViewModel clinic;
  final Bill bill;

  static Future<void> show(BuildContext context, ClinicViewModel clinic, Bill bill) {
    return showDialog(
      context: context,
      builder: (context) => BillPreviewDialog(clinic: clinic, bill: bill),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        bill.billNumber,
        style: AppTypography.headingSmall.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row('Type', bill.isSessionBill ? 'Session' : 'Consultation'),
            if (bill.isConsultationBill)
              _row('Consultation Fee', _money(bill.consultationCharge)),
            if (bill.isSessionBill) _row('Session Fee', _money(bill.treatmentFee)),
            if (bill.productName.isNotEmpty)
              _row('Product — ${bill.productName}', _money(bill.productCost)),
            const Divider(height: 24),
            _row('Total', _money(bill.totalAmount), bold: true),
            _row('Payment Mode', bill.paymentMethod.isEmpty ? '—' : bill.paymentMethod),
            _row('Status', bill.isPaid ? 'Paid' : 'Payment Pending'),
            if (bill.paidAt != null)
              _row('Paid On', DateFormat('d MMM yyyy, h:mm a').format(bill.paidAt!.toLocal())),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5, color: const Color(0xFF6B7280)),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: const Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }
}
